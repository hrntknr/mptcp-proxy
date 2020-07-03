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
 neighbor ens3 interface peer-group REMOTE
 neighbor ens4 interface peer-group REMOTE
 neighbor ens5 interface peer-group REMOTE
 neighbor ens6 interface peer-group REMOTE
 neighbor ens7 interface peer-group REMOTE
 neighbor ens8 interface peer-group REMOTE
 neighbor ens9 interface peer-group REMOTE
 !
 address-family ipv6 unicast
  network fc30::1/64
  network fc31::1/64
  network fc40::1/64
  network fc50::1/64
  network fc60::1/64
  network fc70::1/64
  network fc80::1/64
  neighbor REMOTE activate
 exit-address-family
exit

exit
write memory
EOS
