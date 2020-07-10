#!/bin/bash -eu
echo "net.ipv6.conf.all.forwarding=1" >>/etc/sysctl.conf
sysctl -p
sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
systemctl restart frr
vtysh <<EOS
configure terminal

router bgp 65006
 bgp router-id 192.168.100.6
 neighbor REMOTE peer-group
 neighbor REMOTE remote-as external
 neighbor REMOTE capability extended-nexthop
 neighbor enp2s0 interface peer-group REMOTE
 !
 address-family ipv6 unicast
  network fc60::2/64
  neighbor REMOTE activate
 exit-address-family
exit

exit
write memory
EOS
