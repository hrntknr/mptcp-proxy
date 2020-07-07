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

	coll, err := ebpf.NewCollection(spec)
	if err != nil {
		return err
	}

	mptcpLB := coll.Programs["mptcp_proxy"]
	if mptcpLB == nil {
		return fmt.Errorf("eBPF prog 'mptcp_proxy' not found")
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
