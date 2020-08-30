//
// Simple example that received frames from one link, swaps the MAC addresses and sends the packets back out
// the same link.
//
// The link and associated channel are passed as command line args. The easiest way to direct all packets arriving
// at a link to a single channel is with ethtool -X.
//
use afxdp::buf::Buf;
use afxdp::mmaparea::{MmapArea, MmapAreaOptions};
use afxdp::socket::{Socket, SocketRx, SocketTx};
use afxdp::umem::Umem;
use afxdp::PENDING_LEN;
use arraydeque::{ArrayDeque, Wrapping};
use libbpf_sys::{
    bpf_object, bpf_prog_load, bpf_set_link_xdp_fd, xsk_ring_cons, xsk_ring_prod, xsk_socket,
    xsk_socket__create, xsk_socket__fd, xsk_socket_config, BPF_PROG_TYPE_XDP, XDP_COPY,
    XDP_FLAGS_DRV_MODE, XDP_FLAGS_UPDATE_IF_NOEXIST, XDP_USE_NEED_WAKEUP, XDP_ZEROCOPY,
    XSK_RING_CONS__DEFAULT_NUM_DESCS, XSK_RING_PROD__DEFAULT_NUM_DESCS,
};
use libc::c_int;
use pnet::datalink::interfaces;
use rlimit::{setrlimit, Resource, RLIM_INFINITY};
use std::cmp::min;
use std::ffi::CString;
use std::sync::Arc;

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

const HUGE_TLB: bool = false;
const IF_NAME: &str = "ens1f0";
const OBJ_PATH: &str = "./mptcp_proxy_kern.o";
const QUEUE: usize = 0;
const BUF_NUM: usize = 4096;
const BUF_SIZE: usize = 4096;
const BATCH_SIZE: usize = 64;
const ZERO_COPY: bool = false;
const COPY: bool = false;

fn main() {
    assert!(setrlimit(Resource::MEMLOCK, RLIM_INFINITY, RLIM_INFINITY).is_ok());

    let ifaces = interfaces();
    let ifaces = ifaces.iter().filter(|e| e.name == IF_NAME).next();
    let iface = match ifaces {
        Some(iface) => iface,
        None => panic!("not found interface: {}", IF_NAME),
    };

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

    let mut obj: *mut bpf_object = std::ptr::null_mut();
    let obj_ptr: *mut *mut bpf_object = &mut obj;
    let obj_path_ptr = CString::new(OBJ_PATH).unwrap();
    let mut prog_fd: c_int = 0;
    let err = unsafe {
        bpf_prog_load(
            obj_path_ptr.as_ptr(),
            BPF_PROG_TYPE_XDP,
            obj_ptr,
            &mut prog_fd,
        )
    };
    if err != 0 {
        panic!("bpf_prog_load failed")
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

    // Create a local buf pool and get bufs from the global pool. Since there are no other users of the pool, grab
    // all the bufs.
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
                    match r {
                        Ok(n) => print!("Receive: {}\n", n),
                        Err(err) => println!("error: {:?}", err),
                    }
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
                Ok(n) => print!("Forward: {}\n", n),
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
