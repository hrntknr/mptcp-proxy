package main

import (
	"bytes"
	"crypto/sha1"
	"encoding/binary"
	"net"
	"os"
	"os/signal"
	"strconv"
	"syscall"

	"github.com/bradfitz/gomemcache/memcache"
	"github.com/google/gopacket"
	"github.com/google/gopacket/layers"
	"github.com/google/gopacket/pcap"
	log "github.com/sirupsen/logrus"
)

const TCPOPT_EOL = 0
const TCPOPT_MPTCP = 30

const MPTCP_SUB_CAPABLE = 0

const MPTCP_SUB_LEN_CAPABLE_SYN = 12
const MPTCP_SUB_LEN_CAPABLE_ACK = 20

func main() {
	if err := startServer(); err != nil {
		log.Fatal(err)
	}
}

func startServer() error {
	log.Info("Starting mptcp-server ...")

	mc := memcache.New(config.Memcached...)

	iface, err := net.InterfaceByName(config.Iface)
	if err != nil {
		return err
	}

	handle, err := pcap.OpenLive(iface.Name, 0xffff, false, pcap.BlockForever)
	if err != nil {
		return err
	}

	if err = handle.SetBPFFilter(config.BPFFilter); err != nil {
		return err
	}

	go func() {
		packetSource := gopacket.NewPacketSource(handle, layers.LayerTypeEthernet)
		for packet := range packetSource.Packets() {
			ethLayer, ok := packet.Layer(layers.LayerTypeEthernet).(*layers.Ethernet)
			if !ok {
				return
			}
			if !bytes.Equal(ethLayer.SrcMAC, iface.HardwareAddr) {
				return
			}
			tcpLayer, ok := packet.Layer(layers.LayerTypeTCP).(*layers.TCP)
			if !ok {
				return
			}
			for _, opt := range tcpLayer.Options {
				switch opt.OptionType {
				case TCPOPT_EOL:
					break
				case TCPOPT_MPTCP:
					subType := opt.OptionData[0] >> 4
					switch subType {
					case MPTCP_SUB_CAPABLE:
						hash := sha1.New()
						hash.Write([]byte(opt.OptionData[2:10]))
						result := hash.Sum(nil)
						token := binary.BigEndian.Uint32(result[:4])

						log.Debugf("new sender token: %d", token)

						if err := mc.Set(&memcache.Item{
							Key:   strconv.FormatUint(uint64(token), 10),
							Value: []byte(strconv.FormatUint(uint64(config.BackendIndex), 10)),
						}); err != nil {
							log.Warn(err)
						}
					}
				}
			}
		}

	}()

	log.Infof("Running mptcp-proxy on %s", iface.Name)

	quit := make(chan os.Signal)
	signal.Notify(quit, syscall.SIGINT, syscall.SIGTERM)
	<-quit

	log.Info("Stopping mptcp-proxy ...")
	return nil
}
