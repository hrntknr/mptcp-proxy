#!/bin/bash -eu
echo "net.ipv6.conf.all.forwarding=1" >>/etc/sysctl.conf
sysctl -p
sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
systemctl restart frr
vtysh <<EOS
configure terminal

router bgp 65002
 bgp router-id 192.168.100.2
 neighbor REMOTE peer-group
 neighbor REMOTE remote-as external
 neighbor REMOTE capability extended-nexthop
 neighbor enp2s0 interface peer-group REMOTE
 neighbor enp3s0 interface peer-group REMOTE
 neighbor enp4s0 interface peer-group REMOTE
 neighbor enp5s0 interface peer-group REMOTE
 neighbor enp6s0 interface peer-group REMOTE
 neighbor enp7s0 interface peer-group REMOTE
 neighbor enp8s0 interface peer-group REMOTE
 !
 address-family ipv6 unicast
  network fc23:1::1/64
  network fc23:2::1/64
  network fc24::1/64
  network fc25::1/64
  network fc26::1/64
  network fc27::1/64
  network fc28::1/64
  neighbor REMOTE activate
 exit-address-family
exit

exit
write memory
EOS
