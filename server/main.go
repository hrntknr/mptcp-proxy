package main

import (
	"bytes"
	"context"
	"crypto/sha1"
	"encoding/binary"
	"encoding/json"
	"net"
	"os"
	"os/signal"
	"strconv"
	"syscall"
	"time"

	"github.com/go-redis/redis/v8"
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

type sessionInfo struct {
	Dst net.IP `json:"dst"`
	Src net.IP `json:"src"`
}

func main() {
	if err := startServer(); err != nil {
		log.Fatal(err)
	}
}

func startServer() error {
	log.Info("Starting mptcp-server ...")
	joinTimeout, err := time.ParseDuration(config.JoinTimeout)
	if err != nil {
		return err
	}

	rdb := redis.NewClient(&redis.Options{
		Addr: config.Redus,
	})

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

						json, err := json.Marshal(sessionInfo{
							Dst: net.ParseIP(config.Dst),
							Src: net.ParseIP(config.Src),
						})
						if err != nil {
							log.Warn(err)
						}

						if _, err := rdb.Set(context.Background(), strconv.FormatUint(uint64(token), 10), json, joinTimeout).Result(); err != nil {
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
