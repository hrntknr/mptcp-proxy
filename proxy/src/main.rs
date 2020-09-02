use afxdp::buf::Buf;
use afxdp::mmaparea::{MmapArea, MmapAreaOptions};
use afxdp::socket::{Socket, SocketRx, SocketTx};
use afxdp::umem::Umem;
use afxdp::PENDING_LEN;
use arraydeque::{ArrayDeque, Wrapping};
use async_std::task;
use config::{Config, Environment, File};
use env_logger;
use libbpf_sys::{
    bpf_map__fd, bpf_map_update_elem, bpf_object, bpf_object__find_map_by_name, bpf_prog_load,
    bpf_set_link_xdp_fd, xsk_ring_cons, xsk_ring_prod, xsk_socket, xsk_socket__create,
    xsk_socket__fd, xsk_socket_config, BPF_ANY, BPF_PROG_TYPE_XDP, XDP_COPY, XDP_FLAGS_DRV_MODE,
    XDP_FLAGS_UPDATE_IF_NOEXIST, XDP_USE_NEED_WAKEUP, XDP_ZEROCOPY,
    XSK_RING_CONS__DEFAULT_NUM_DESCS, XSK_RING_PROD__DEFAULT_NUM_DESCS,
};
use libc::c_int;
use pnet::datalink::interfaces;
use pnet::packet::ethernet::{EtherTypes, MutableEthernetPacket};
use pnet::packet::ip::IpNextHeaderProtocol;
use pnet::packet::ipv6::{Ipv6Packet, MutableIpv6Packet};
use pnet::packet::tcp::{TcpOptionNumber, TcpPacket};
use pnet::packet::{MutablePacket, Packet};
use redis::aio::MultiplexedConnection;
use redis::RedisError;
use rlimit::{setrlimit, Resource, RLIM_INFINITY};
use serde::{Deserialize, Serialize};
use serde_json::from_str;
use std::cmp::min;
use std::convert::TryInto;
use std::ffi::{c_void, CString};
use std::net::Ipv6Addr;
use std::sync::mpsc;
use std::sync::Arc;
use std::time::Duration;

const BACKEND_ARRAY_SIZE: usize = 64;

const HUGE_TLB: bool = false;
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
    redis: String,
    retry: usize,
    retry_wait: usize,
}

#[derive(Serialize, Deserialize, Debug)]
struct SessionInfoString {
    dst: String,
    src: String,
}
struct SessionInfo {
    dst: Ipv6Addr,
    src: Ipv6Addr,
    flow: Flow,
}

struct Flow {
    s_addr: Option<Ipv6Addr>,
    s_port: u16,
    d_addr: Option<Ipv6Addr>,
    d_port: u16,
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
#[repr(C)]
struct SubflowCacheKey {
    s_addr: [u8; 16],
    s_port: u16,
    d_addr: [u8; 16],
    d_port: u16,
}

#[allow(dead_code)]
#[repr(C)]
struct SubflowCacheInfo {
    src: [u8; 16],
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
    env_logger::from_env(env_logger::Env::new().filter_or("LOG_LEVEL", "info")).init();

    let mut settings = Config::default();
    settings
        .merge(File::with_name("proxy_config"))
        .unwrap()
        .merge(Environment::default())
        .unwrap();

    let cfg = settings.try_into::<AppConfig>().unwrap();

    task::block_on(start_proxy(cfg))
}

async fn start_proxy(cfg: AppConfig) {
    assert!(setrlimit(Resource::MEMLOCK, RLIM_INFINITY, RLIM_INFINITY).is_ok());

    let ifaces = interfaces();
    let iface = ifaces
        .iter()
        .filter(|e| e.name == cfg.iface)
        .next()
        .unwrap();

    log::debug!("Connecting to redis: {}", cfg.redis);
    let client = redis::Client::open(cfg.redis).unwrap();

    log::debug!("Loading bpf program: {}", cfg.xdp_prog);
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
    let subflow_cache = unsafe {
        bpf_object__find_map_by_name(obj, CString::new("subflow_cache").unwrap().as_ptr())
    };
    let subflow_cache_fd = unsafe { bpf_map__fd(subflow_cache) };

    for (i, service) in cfg.services.iter().enumerate() {
        log::debug!("Registing a vip: {}", service.vip);
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
            log::debug!("Registing a backend: {}", backend);
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

    log::debug!("Attach to interface: {}", iface.name);
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

    log::debug!("Creating af_xdp socket, queue_id: {}", cfg.queue_id);
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

    let mut xsk_cfg = xsk_socket_config {
        rx_size: XSK_RING_CONS__DEFAULT_NUM_DESCS,
        tx_size: XSK_RING_PROD__DEFAULT_NUM_DESCS,
        xdp_flags: XDP_FLAGS_UPDATE_IF_NOEXIST,
        bind_flags: XDP_USE_NEED_WAKEUP as u16,
        libbpf_flags: 0,
    };
    if ZERO_COPY {
        xsk_cfg.bind_flags = xsk_cfg.bind_flags | XDP_ZEROCOPY as u16;
    }
    if COPY {
        xsk_cfg.bind_flags = xsk_cfg.bind_flags | XDP_COPY as u16;
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
            cfg.queue_id as u32,
            umem.umem.lock().unwrap().as_mut(),
            rx.as_mut(),
            tx.as_mut(),
            &xsk_cfg,
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

    log::debug!("Initialization completed");
    log::info!("Starting the proxy...");

    let custom = BufCustom {};
    let mut fq_deficit = 0;
    let (sender, receiver) = mpsc::channel();
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
                    for mut buf in v.pop_front() {
                        let retry = cfg.retry;
                        let retry_wait = cfg.retry_wait;
                        let client = client.clone();
                        let sender = sender.clone();
                        let task = async move {
                            let mut conn =
                                client.get_multiplexed_async_std_connection().await.unwrap();
                            let info =
                                process_eth(&mut buf.data, &mut conn, retry, retry_wait).await;
                            match info {
                                Some(info) => {
                                    let cache_key = SubflowCacheKey {
                                        s_addr: info.flow.s_addr.unwrap().octets(),
                                        s_port: info.flow.s_port,
                                        d_addr: info.flow.d_addr.unwrap().octets(),
                                        d_port: info.flow.d_port,
                                    };
                                    let cache_key_ptr =
                                        &cache_key as *const SubflowCacheKey as *const c_void;
                                    let cache_value = SubflowCacheInfo {
                                        src: info.src.octets(),
                                        dst: info.dst.octets(),
                                    };
                                    let cache_value_ptr =
                                        &cache_value as *const SubflowCacheInfo as *const c_void;

                                    let err = unsafe {
                                        bpf_map_update_elem(
                                            subflow_cache_fd,
                                            cache_key_ptr,
                                            cache_value_ptr,
                                            BPF_ANY as u64,
                                        )
                                    };
                                    if err != 0 {
                                        panic!("bpf_map_update_elem failed")
                                    }
                                }
                                None => {}
                            }

                            sender.send(buf).unwrap();
                        };
                        task::spawn(task);
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

        for buf in receiver.try_recv() {
            v.push_back(buf);
        }

        // Forward
        if !v.is_empty() {
            let r = skt1tx.try_send(&mut v, BATCH_SIZE);
            match r {
                Ok(_) => {}
                Err(err) => log::error!("error: {:?}", err),
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

async fn process_tcp(
    buf: &[u8],
    conn: &mut MultiplexedConnection,
    retry: usize,
    retry_wait: usize,
) -> Option<SessionInfo> {
    let packet_tcp = TcpPacket::new(buf).unwrap();
    for opt in packet_tcp.get_options_iter() {
        match opt.get_number() {
            TcpOptionNumber(0) => {
                return None;
            }
            TcpOptionNumber(30) => {
                let opt_payload = opt.payload();
                match opt_payload[0] >> 4 {
                    1 => {
                        if opt_payload.len() != 10 {
                            continue;
                        }
                        let token: [u8; 4] = opt_payload[2..6].try_into().unwrap();
                        let token = unsafe { std::mem::transmute::<[u8; 4], u32>(token) }
                            .to_be()
                            .to_string();
                        log::debug!("Received mp_join, token: {}", token);
                        let mut retry = retry;
                        let info = loop {
                            task::sleep(Duration::from_millis(retry_wait as u64)).await;
                            let r: Result<String, RedisError> =
                                redis::cmd("GET").arg(&token).query_async(conn).await;
                            match r {
                                Ok(r) => break Some(r),
                                Err(_) => {
                                    if retry <= 0 {
                                        break None;
                                    }
                                    retry -= 1;
                                }
                            };
                        };
                        let info = match info {
                            Some(s) => s,
                            None => {
                                log::error!("error: token not found, token: {}", token);
                                continue;
                            }
                        };
                        let info: SessionInfoString = match from_str(&info) {
                            Ok(info) => info,
                            Err(err) => {
                                log::error!("error: {:?}", err);
                                continue;
                            }
                        };
                        let src: Ipv6Addr = match info.src.parse() {
                            Ok(info) => info,
                            Err(err) => {
                                log::error!("error: {:?}", err);
                                continue;
                            }
                        };
                        let dst: Ipv6Addr = match info.dst.parse() {
                            Ok(info) => info,
                            Err(err) => {
                                log::error!("error: {:?}", err);
                                continue;
                            }
                        };
                        log::debug!("Redirect to {}, token: {}", dst, token);
                        return Some(SessionInfo {
                            src: src,
                            dst: dst,
                            flow: Flow {
                                s_addr: None,
                                s_port: packet_tcp.get_source(),
                                d_addr: None,
                                d_port: packet_tcp.get_destination(),
                            },
                        });
                    }
                    _ => {}
                }
            }
            _ => {}
        }
    }
    None
}

async fn process_ip6(
    buf: &[u8],
    conn: &mut MultiplexedConnection,
    retry: usize,
    retry_wait: usize,
) -> Option<SessionInfo> {
    let packet_ip6 = Ipv6Packet::new(buf).unwrap();
    if packet_ip6.get_next_header() != IpNextHeaderProtocol(6) {
        return None;
    }
    let mut info = match process_tcp(packet_ip6.payload(), conn, retry, retry_wait).await {
        Some(info) => info,
        None => return None,
    };
    info.flow.s_addr = Some(packet_ip6.get_source());
    info.flow.d_addr = Some(packet_ip6.get_destination());
    Some(info)
}

async fn process_ip6ip6(
    buf: &mut [u8],
    conn: &mut MultiplexedConnection,
    retry: usize,
    retry_wait: usize,
) -> Option<SessionInfo> {
    let mut packet_ip6ip6 = MutableIpv6Packet::new(buf).unwrap();
    if packet_ip6ip6.get_next_header() != IpNextHeaderProtocol(41) {
        return None;
    }
    let packet_ip6 = Ipv6Packet::new(packet_ip6ip6.payload()).unwrap();
    if packet_ip6.get_next_header() != IpNextHeaderProtocol(6) {
        return None;
    }
    let info = match process_ip6(packet_ip6ip6.payload(), conn, retry, retry_wait).await {
        None => return None,
        Some(info) => info,
    };
    packet_ip6ip6.set_source(info.src);
    packet_ip6ip6.set_destination(info.dst);
    Some(info)
}

async fn process_eth(
    buf: &mut [u8],
    conn: &mut MultiplexedConnection,
    retry: usize,
    retry_wait: usize,
) -> Option<SessionInfo> {
    let mut packet_eth = MutableEthernetPacket::new(buf).unwrap();
    if packet_eth.get_ethertype() != EtherTypes::Ipv6 {
        return None;
    }
    let info = match process_ip6ip6(packet_eth.payload_mut(), conn, retry, retry_wait).await {
        None => return None,
        Some(info) => info,
    };
    let src = packet_eth.get_source();
    let dst = packet_eth.get_destination();
    packet_eth.set_source(dst);
    packet_eth.set_destination(src);
    Some(info)
}
