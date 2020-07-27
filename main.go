package main

import (
	"encoding/binary"
	"fmt"
	"net"
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

const SERVICE_MAP_SIZE = 64
const BACKEND_ARRAY_SIZE = 64

func main() {
	if err := startProxy(); err != nil {
		fmt.Println(err)
		log.Fatal(err)
	}
}

func startProxy() error {
	log.Info("Starting mptcp-proxy ...")

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

	backendsLen := coll.Maps["backends_len"]
	if backendsLen == nil {
		return fmt.Errorf("eBPF map 'backends_len' not found")
	}

	xsks := coll.Maps["xsks_map"]
	if xsks == nil {
		return fmt.Errorf("eBPF map 'xsks_map' not found")
	}

	newClientMap := coll.Maps["new_client"]
	if newClientMap == nil {
		return fmt.Errorf("eBPF map 'new_client' not found")
	}
	reader, err := perf.NewReader(newClientMap, os.Getpagesize())
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
		if err := backendsLen.Put(uint32(i), uint32(len(serviceConf.Backends))); err != nil {
			return err
		}
	}

	// xsk, err := xdp.NewRawSocket(link.Attrs().Index, config.QueueID)
	// if err != nil {
	// 	return err
	// }
	// if err = xsks.Put(uint32(config.QueueID), uint32(xsk.FD())); err != nil {
	// 	return err
	// }

	// go func() {
	// 	for {
	// 		xsk.Fill(xsk.GetDescs(xsk.NumFreeFillSlots()))

	// 		numRx, _, err := xsk.Poll(-1)
	// 		if err != nil {
	// 			log.Error(err)
	// 			continue
	// 		}
	// 		if numRx > 0 {
	// 			log.Debugf("recv numRx: %d", numRx)
	// 			descs := xsk.Receive(numRx)
	// 			for i := range descs {
	// 				log.Debugf("desc: %+v", descs[i])
	// 				frame := xsk.GetFrame(descs[i])
	// 				fmt.Print(hex.Dump(frame))
	// 			}
	// 			xsk.Transmit(descs)
	// 		}
	// 	}
	// }()

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
