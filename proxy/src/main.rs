use afxdp::buf::Buf;
use afxdp::mmaparea::{MmapArea, MmapAreaOptions};
use afxdp::socket::{Socket, SocketRx, SocketTx};
use afxdp::umem::Umem;
use afxdp::PENDING_LEN;
use arraydeque::{ArrayDeque, Wrapping};
use config::{Config, Environment, File};
use libbpf_sys::{
    bpf_map__fd, bpf_map_update_elem, bpf_object, bpf_object__find_map_by_name, bpf_prog_load,
    bpf_set_link_xdp_fd, xsk_ring_cons, xsk_ring_prod, xsk_socket, xsk_socket__create,
    xsk_socket__fd, xsk_socket_config, BPF_ANY, BPF_PROG_TYPE_XDP, XDP_COPY, XDP_FLAGS_DRV_MODE,
    XDP_FLAGS_UPDATE_IF_NOEXIST, XDP_USE_NEED_WAKEUP, XDP_ZEROCOPY,
    XSK_RING_CONS__DEFAULT_NUM_DESCS, XSK_RING_PROD__DEFAULT_NUM_DESCS,
};
use libc::c_int;
use pnet::datalink::interfaces;
use rlimit::{setrlimit, Resource, RLIM_INFINITY};
use serde::{Deserialize, Serialize};
use std::cmp::min;
use std::ffi::{c_void, CString};
use std::net::Ipv6Addr;
use std::sync::Arc;

const BACKEND_ARRAY_SIZE: usize = 64;

const HUGE_TLB: bool = false;
const QUEUE: usize = 0;
const BUF_NUM: usize = 4096;
const BUF_SIZE: usize = 4096;
const BATCH_SIZE: usize = 64;
const ZERO_COPY: bool = false;
const COPY: bool = false;

#[derive(Serialize, Deserialize, Debug)]
struct AppConfig {
    iface: String,
    queue_id: isize,
    xdp_prog: String,
    services: Vec<ServiceConfig>,
    memcached: Vec<String>,
}

#[derive(Serialize, Deserialize, Debug)]
struct ServiceConfig {
    port: u16,
    vip: Ipv6Addr,
    backends: Vec<Ipv6Addr>,
    src: Ipv6Addr,
}

#[allow(dead_code)]
#[repr(C)]
struct ServiceKey {
    vip: [u8; 16],
    port: u16,
}

#[allow(dead_code)]
#[repr(C)]
struct ServiceInfo {
    id: u32,
    src: [u8; 16],
}

#[allow(dead_code)]
#[repr(C)]
struct BackendInfo {
    dst: [u8; 16],
}

#[allow(dead_code)]
pub struct RawSocket<'a, T: std::default::Default + std::marker::Copy> {
    umem: Arc<Umem<'a, T>>,
    socket: Box<xsk_socket>,
}
#[allow(dead_code)]
pub struct RawSocketRx<'a, T: std::default::Default + std::marker::Copy> {
    socket: Arc<Socket<'a, T>>,
    fd: std::os::raw::c_int,
    rx: Box<xsk_ring_cons>,
}
#[allow(dead_code)]
pub struct RawSocketTx<'a, T: std::default::Default + std::marker::Copy> {
    socket: Arc<Socket<'a, T>>,
    fd: std::os::raw::c_int,
    tx: Box<xsk_ring_prod>,
}

#[derive(Default, Copy, Clone)]
struct BufCustom {}

fn main() {
    let mut settings = Config::default();
    settings
        .merge(File::with_name("config"))
        .unwrap()
        .merge(Environment::default())
        .unwrap();

    let cfg = settings.try_into::<AppConfig>().unwrap();

    start_proxy(cfg)
}

fn start_proxy(cfg: AppConfig) {
    assert!(setrlimit(Resource::MEMLOCK, RLIM_INFINITY, RLIM_INFINITY).is_ok());

    let ifaces = interfaces();
    let ifaces = ifaces.iter().filter(|e| e.name == cfg.iface).next();
    let iface = match ifaces {
        Some(iface) => iface,
        None => panic!("not found interface: {}", cfg.iface),
    };

    let mut obj: *mut bpf_object = std::ptr::null_mut();
    let obj_ptr: *mut *mut bpf_object = &mut obj;
    let mut prog_fd: c_int = 0;
    let err = unsafe {
        bpf_prog_load(
            CString::new(cfg.xdp_prog).unwrap().as_ptr(),
            BPF_PROG_TYPE_XDP,
            obj_ptr,
            &mut prog_fd,
        )
    };
    if err != 0 {
        panic!("bpf_prog_load failed")
    }

    let services =
        unsafe { bpf_object__find_map_by_name(obj, CString::new("services").unwrap().as_ptr()) };
    let services_fd = unsafe { bpf_map__fd(services) };
    let backends =
        unsafe { bpf_object__find_map_by_name(obj, CString::new("backends").unwrap().as_ptr()) };
    let backends_fd = unsafe { bpf_map__fd(backends) };
    let backends_len = unsafe {
        bpf_object__find_map_by_name(obj, CString::new("backends_len").unwrap().as_ptr())
    };
    let backends_len_fd = unsafe { bpf_map__fd(backends_len) };

    for (i, service) in cfg.services.iter().enumerate() {
        let service_key = ServiceKey {
            port: service.port,
            vip: service.vip.octets(),
        };
        let service_key_ptr = &service_key as *const ServiceKey as *const c_void;
        let service_value = ServiceInfo {
            id: i as u32,
            src: service.src.octets(),
        };
        let service_value_ptr = &service_value as *const ServiceInfo as *const c_void;

        let err = unsafe {
            bpf_map_update_elem(
                services_fd,
                service_key_ptr,
                service_value_ptr,
                BPF_ANY as u64,
            )
        };
        if err != 0 {
            panic!("bpf_map_update_elem failed")
        }

        for (j, backend) in service.backends.iter().enumerate() {
            let backend_key: u32 = (BACKEND_ARRAY_SIZE * i + j) as u32;
            let backend_key_ptr = &backend_key as *const u32 as *const c_void;
            let backend_value = BackendInfo {
                dst: backend.octets(),
            };
            let backend_value_ptr = &backend_value as *const BackendInfo as *const c_void;

            let err = unsafe {
                bpf_map_update_elem(
                    backends_fd,
                    backend_key_ptr,
                    backend_value_ptr,
                    BPF_ANY as u64,
                )
            };
            if err != 0 {
                panic!("bpf_map_update_elem failed")
            }
        }

        let backend_len_key: u32 = i as u32;
        let backend_len_key_ptr = &backend_len_key as *const u32 as *const c_void;
        let backend_len_value: u32 = service.backends.len() as u32;
        let backend_len_value_ptr = &backend_len_value as *const u32 as *const c_void;

        let err = unsafe {
            bpf_map_update_elem(
                backends_len_fd,
                backend_len_key_ptr,
                backend_len_value_ptr,
                BPF_ANY as u64,
            )
        };
        if err != 0 {
            panic!("bpf_map_update_elem failed")
        }
    }

    let err = unsafe {
        bpf_set_link_xdp_fd(
            iface.index as c_int,
            prog_fd,
            XDP_FLAGS_UPDATE_IF_NOEXIST | XDP_FLAGS_DRV_MODE,
        )
    };
    if err != 0 {
        panic!("bpf_set_link_xdp_fd failed")
    }

    let r = MmapArea::new(BUF_NUM, BUF_SIZE, MmapAreaOptions { huge_tlb: HUGE_TLB });
    let (area, buf_pool) = match r {
        Ok((area, buf_pool)) => (area, buf_pool),
        Err(err) => panic!("no mmap for you: {:?}", err),
    };

    let r = Umem::new(
        area.clone(),
        XSK_RING_CONS__DEFAULT_NUM_DESCS,
        XSK_RING_PROD__DEFAULT_NUM_DESCS,
    );
    let (umem1, mut umem1cq, mut umem1fq) = match r {
        Ok(umem) => umem,
        Err(err) => panic!("no umem for you: {:?}", err),
    };

    let mut cfg = xsk_socket_config {
        rx_size: XSK_RING_CONS__DEFAULT_NUM_DESCS,
        tx_size: XSK_RING_PROD__DEFAULT_NUM_DESCS,
        xdp_flags: XDP_FLAGS_UPDATE_IF_NOEXIST,
        bind_flags: XDP_USE_NEED_WAKEUP as u16,
        libbpf_flags: 0,
    };
    if ZERO_COPY {
        cfg.bind_flags = cfg.bind_flags | XDP_ZEROCOPY as u16;
    }
    if COPY {
        cfg.bind_flags = cfg.bind_flags | XDP_COPY as u16;
    }

    let mut rx: Box<xsk_ring_cons> = Default::default();
    let mut tx: Box<xsk_ring_prod> = Default::default();

    let mut xsk: *mut xsk_socket = std::ptr::null_mut();
    let xsk_ptr: *mut *mut xsk_socket = &mut xsk;

    let if_name_c = CString::new(iface.name.as_str()).unwrap();

    let umem = umem1.clone();

    let err = unsafe {
        xsk_socket__create(
            xsk_ptr,
            if_name_c.as_ptr(),
            QUEUE as u32,
            umem.umem.lock().unwrap().as_mut(),
            rx.as_mut(),
            tx.as_mut(),
            &cfg,
        )
    };
    if err != 0 {
        panic!("xsk_socket__create failed")
    }
    let arc = Arc::new(unsafe {
        std::mem::transmute::<RawSocket<BufCustom>, Socket<BufCustom>>(RawSocket {
            umem: umem,
            socket: { Box::from_raw(*xsk_ptr) },
        })
    });
    let mut skt1rx = unsafe {
        std::mem::transmute::<RawSocketRx<BufCustom>, SocketRx<BufCustom>>(RawSocketRx {
            socket: arc.clone(),
            fd: { xsk_socket__fd(*xsk_ptr) },
            rx: rx,
        })
    };
    let mut skt1tx = unsafe {
        std::mem::transmute::<RawSocketTx<BufCustom>, SocketTx<BufCustom>>(RawSocketTx {
            socket: arc.clone(),
            fd: { xsk_socket__fd(*xsk_ptr) },
            tx: tx,
        })
    };

    let mut bufs: Vec<Buf<BufCustom>> = Vec::with_capacity(BUF_NUM);
    let r = buf_pool.lock().unwrap().get(&mut bufs, BUF_NUM);
    match r {
        Ok(n) => {
            if n != BUF_NUM {
                panic!("failed to get initial bufs {} {}", n, BUF_NUM,);
            }
        }
        Err(err) => panic!("error: {:?}", err),
    }

    let r = umem1fq.fill(
        &mut bufs,
        min(XSK_RING_PROD__DEFAULT_NUM_DESCS as usize, BUF_NUM),
    );
    match r {
        Ok(n) => {
            if n != min(XSK_RING_PROD__DEFAULT_NUM_DESCS as usize, BUF_NUM) {
                panic!(
                    "Initial fill of umem incomplete. Wanted {} got {}.",
                    BUF_NUM, n
                );
            }
        }
        Err(err) => panic!("error: {:?}", err),
    }

    let mut v: ArrayDeque<[Buf<BufCustom>; PENDING_LEN], Wrapping> = ArrayDeque::new();

    let custom = BufCustom {};
    let mut fq_deficit = 0;
    loop {
        // Service completion queue
        let r = umem1cq.service(&mut bufs, BATCH_SIZE);
        match r {
            Ok(_) => {}
            Err(err) => panic!("error: {:?}", err),
        }

        // Receive
        let r = skt1rx.try_recv(&mut v, BATCH_SIZE, custom);
        match r {
            Ok(n) => {
                if n > 0 {
                    parse_packet(&mut v);
                    fq_deficit += n;
                } else {
                    if umem1fq.needs_wakeup() {
                        skt1rx.wake();
                    }
                }
            }
            Err(err) => {
                panic!("error: {:?}", err);
            }
        }

        // Forward
        if !v.is_empty() {
            let r = skt1tx.try_send(&mut v, BATCH_SIZE);
            match r {
                Ok(_) => {}
                Err(err) => println!("error: {:?}", err),
            }
        }

        // Fill buffers
        if fq_deficit > 0 {
            let r = umem1fq.fill(&mut bufs, fq_deficit);
            match r {
                Ok(n) => {
                    fq_deficit -= n;
                }
                Err(err) => panic!("error: {:?}", err),
            }
        }
    }
}

fn parse_packet(bufs: &mut ArrayDeque<[Buf<BufCustom>; PENDING_LEN], Wrapping>) {
    for buf in bufs {
        print!("{:?}\n", buf.data);
    }
}
