use config::{Config, Environment, File};
use libbpf_sys::{
    bpf_map__fd, bpf_map_update_elem, bpf_object, bpf_object__find_map_by_name, bpf_prog_load,
    bpf_set_link_xdp_fd, BPF_ANY, BPF_PROG_TYPE_XDP, XDP_FLAGS_DRV_MODE,
    XDP_FLAGS_UPDATE_IF_NOEXIST,
};
use libc::c_int;
use pnet::datalink::interfaces;
use rlimit::{setrlimit, Resource, RLIM_INFINITY};
use serde::{Deserialize, Serialize};
use std::ffi::{c_void, CString};
use std::net::Ipv6Addr;

const BACKEND_ARRAY_SIZE: usize = 64;

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
}
