package main

import (
	"encoding/binary"
	"fmt"
	"os"
	"os/signal"
	"strconv"
	"syscall"

	"github.com/bradfitz/gomemcache/memcache"
	"github.com/cilium/ebpf"
	"github.com/cilium/ebpf/perf"
	log "github.com/sirupsen/logrus"
	"github.com/vishvananda/netlink"
)

func main() {
	if err := startProxy(); err != nil {
		log.Fatal(err)
	}
}

func startProxy() error {
	log.Info("Starting mptcp-server ...")

	mc := memcache.New(config.Memcached...)

	link, err := netlink.LinkByName(config.Iface)
	if err != nil {
		return err
	}

	spec, err := ebpf.LoadCollectionSpec(config.XdpProg)
	if err != nil {
		return err
	}

	coll, err := ebpf.NewCollection(spec)
	if err != nil {
		return err
	}

	mptcpServer := coll.Programs["mptcp_server"]
	if mptcpServer == nil {
		return fmt.Errorf("eBPF prog 'mptcp_server' not found")
	}

	newSession := coll.Maps["new_session"]
	if newSession == nil {
		return fmt.Errorf("eBPF map 'new_session' not found")
	}
	reader, err := perf.NewReader(newSession, os.Getpagesize())
	if err != nil {
		return err
	}

	go func() {
		for {
			record, err := reader.Read()
			if err != nil {
				log.Error(err)
				continue
			}
			senderKey := binary.LittleEndian.Uint64(record.RawSample[:8])
			backendIndex := binary.LittleEndian.Uint32(record.RawSample[8:12])
			log.Debugf("new session!! key: %d, backend: %d", senderKey, backendIndex)
			mc.Set(&memcache.Item{
				Key:   strconv.FormatUint(senderKey, 10),
				Value: []byte(strconv.FormatUint(uint64(backendIndex), 10)),
			})
		}
	}()

	if err := netlink.LinkSetXdpFd(link, mptcpServer.FD()); err != nil {
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
