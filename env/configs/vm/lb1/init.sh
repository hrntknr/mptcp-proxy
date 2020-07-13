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

cat <<EOS >/etc/netplan/99-custom.yaml
network:
  version: 2
  tunnels:
    tun0:
      mode: ip6ip6
      local: fc24::2
      remote: fc25::2
    tun1:
      mode: ip6ip6
      local: fc24::2
      remote: fc26::2
EOS
netplan apply -f

while [ 1 ]; do
  sleep 1
  if [ "$(cat /sys/class/net/tun0/carrier)" = "0" ]; then
    continue
  fi
  if [ "$(cat /sys/class/net/tun1/carrier)" = "0" ]; then
    continue
  fi
  break
done

ipvsadm -A -t [fc10::1]:80 -s rr
ipvsadm -a -t [fc10::1]:80 -r [fc11::2]:80 -g
ipvsadm -a -t [fc10::1]:80 -r [fc12::2]:80 -g
ipvsadm-save

ip addr add fc11::1 peer fc11::2 dev tun0
ip addr add fc12::1 peer fc12::2 dev tun1
