#!/bin/bash -eu
echo "net.ipv6.conf.all.forwarding=1" >>/etc/sysctl.conf
sysctl -p
sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
systemctl restart frr
vtysh <<EOS
configure terminal

router bgp 65005
 bgp router-id 192.168.100.5
 neighbor REMOTE peer-group
 neighbor REMOTE remote-as external
 neighbor REMOTE capability extended-nexthop
 neighbor enp3s0 interface peer-group REMOTE
 !
 address-family ipv6 unicast
  network fc25::2/64
  neighbor REMOTE activate
 exit-address-family
exit

exit
write memory
EOS

mkdir -p /home/ubuntu/go/src/github.com/hrntknr/mptcp-proxy
chown -R ubuntu:ubuntu /home/ubuntu/go/
echo "mptcp_proxy /home/ubuntu/go/src/github.com/hrntknr/mptcp-proxy 9p trans=virtio,version=9p2000.L,nobootwait,rw,_netdev 0 0" >>/etc/fstab
mount -a

TMP=$(mktemp)
wget -q https://golang.org/dl/go1.14.4.linux-amd64.tar.gz -O $TMP
tar -C /usr/local -xzf $TMP
ln -s /usr/local/go/bin/* /usr/local/bin
