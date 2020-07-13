package main

import (
	"encoding/binary"
	"fmt"
	"net"
)

type ServiceKey struct {
	VIP  net.IP
	Port uint16
}

type ServiceInfo struct {
	ID  uint32
	Src net.IP
}

type BackendInfo struct {
	Dst net.IP
}

func (s *ServiceKey) MarshalBinary() (data []byte, err error) {
	if len(s.VIP) != 16 {
		return nil, fmt.Errorf("invalid vip: %s", s.VIP)
	}
	buf := [18]byte{}
	for i := 0; i < 16; i++ {
		buf[i] = s.VIP[i]
	}
	// TODO: ebpf endian check
	binary.LittleEndian.PutUint16(buf[16:18], s.Port)
	return buf[:], nil
}

func (s *ServiceInfo) MarshalBinary() (data []byte, err error) {
	if len(s.Src) != 16 {
		return nil, fmt.Errorf("invalid vip: %s", s.Src)
	}
	buf := [20]byte{}
	// TODO: ebpf endian check
	binary.LittleEndian.PutUint32(buf[0:4], s.ID)
	for i := 0; i < 16; i++ {
		buf[4+i] = s.Src[i]
	}
	return buf[:], nil
}

func (b *BackendInfo) MarshalBinary() (data []byte, err error) {
	if len(b.Dst) != 16 {
		return nil, fmt.Errorf("invalid vip: %s", b.Dst)
	}
	buf := [16]byte{}
	for i := 0; i < 16; i++ {
		buf[i] = b.Dst[i]
	}
	return buf[:], nil
}
