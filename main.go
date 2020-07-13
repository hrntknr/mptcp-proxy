package main

import (
	"fmt"
	"os"
	"os/signal"
	"syscall"

	"github.com/cilium/ebpf"
	log "github.com/sirupsen/logrus"
	"github.com/vishvananda/netlink"
)

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
		Type:       ebpf.HashOfMaps,
		KeySize:    18,
		MaxEntries: 64,
		InnerMap: &ebpf.MapSpec{
			Type:       ebpf.Array,
			KeySize:    4,
			ValueSize:  32,
			MaxEntries: 64,
		},
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
