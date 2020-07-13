#!/bin/bash -eu
echo "net.ipv6.conf.all.forwarding=1" >>/etc/sysctl.conf
sysctl -p
sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
systemctl restart frr
vtysh <<EOS
configure terminal

router bgp 65004
 bgp router-id 192.168.100.4
 neighbor REMOTE peer-group
 neighbor REMOTE remote-as external
 neighbor REMOTE capability extended-nexthop
 neighbor enp3s0 interface peer-group REMOTE
 !
 address-family ipv6 unicast
  network fc24::2/64
  network fc10::1/128
  neighbor REMOTE activate
 exit-address-family
exit

exit
write memory
EOS

ipvsadm -A -t [fc10::1]:80 -s rr
ipvsadm -a -t [fc10::1]:80 -r fc25::2 -i
ipvsadm -a -t [fc10::1]:80 -r fc26::2 -i
ipvsadm-save
