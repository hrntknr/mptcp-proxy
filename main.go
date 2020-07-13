package main

import (
	"fmt"
	"net"
	"os"
	"os/signal"
	"syscall"

	"github.com/cilium/ebpf"
	log "github.com/sirupsen/logrus"
	"github.com/vishvananda/netlink"
)

const SERVICE_MAP_SIZE = 64
const BACKEND_ARRAY_SIZE = 64

func main() {
	if err := startProxy(); err != nil {
		log.Fatal(err)
	}
}

func startProxy() error {
	log.Info("Starting mptcp-proxy ...")
	spec, err := ebpf.LoadCollectionSpec(config.XdpProg)
	if err != nil {
		return err
	}

	spec.Maps["services"] = &ebpf.MapSpec{
		Type:       ebpf.Hash,
		KeySize:    18,
		ValueSize:  20,
		MaxEntries: SERVICE_MAP_SIZE,
	}

	spec.Maps["backends"] = &ebpf.MapSpec{
		Type:       ebpf.Array,
		KeySize:    4,
		ValueSize:  16,
		MaxEntries: BACKEND_ARRAY_SIZE * SERVICE_MAP_SIZE,
	}

	coll, err := ebpf.NewCollection(spec)
	if err != nil {
		return err
	}

	mptcpLB := coll.Programs["mptcp_proxy"]
	if mptcpLB == nil {
		return fmt.Errorf("eBPF prog 'mptcp_proxy' not found")
	}

	services := coll.Maps["services"]
	if services == nil {
		return fmt.Errorf("eBPF map 'services' not found")
	}

	backends := coll.Maps["backends"]
	if backends == nil {
		return fmt.Errorf("eBPF map 'backends' not found")
	}

	for i, serviceConf := range config.Services {
		serviceKey := &ServiceKey{
			VIP:  net.ParseIP(serviceConf.VIP),
			Port: serviceConf.Port,
		}
		serviceInfo := &ServiceInfo{
			ID:  uint32(i),
			Src: net.ParseIP(serviceConf.Src),
		}
		if err := services.Put(serviceKey, serviceInfo); err != nil {
			return err
		}

		for j, backendConf := range serviceConf.Backends {
			backendInfo := &BackendInfo{
				Dst: net.ParseIP(backendConf),
			}
			if err := backends.Put(uint32(BACKEND_ARRAY_SIZE*i+j), backendInfo); err != nil {
				return err
			}
		}
	}

	link, err := netlink.LinkByName(config.Iface)
	if err != nil {
		return err
	}

	if err := netlink.LinkSetXdpFd(link, mptcpLB.FD()); err != nil {
		return err
	}

	defer (func() {
		if err := netlink.LinkSetXdpFd(link, -1); err != nil {
			fmt.Println(err.Error())
		}
	})()

	log.Infof("Running mptcp-proxy on %s", config.Iface)

	quit := make(chan os.Signal)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("Stopping mptcp-proxy ...")
	return nil
}
