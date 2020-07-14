#!/bin/bash -eu
echo "net.ipv6.conf.all.forwarding=1" >>/etc/sysctl.conf
sysctl -p
sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
systemctl restart frr
vtysh <<EOS
configure terminal

router bgp 65003
 bgp router-id 192.168.100.3
 neighbor REMOTE peer-group
 neighbor REMOTE remote-as external
 neighbor REMOTE capability extended-nexthop
 neighbor enp3s0 interface peer-group REMOTE
 neighbor enp4s0 interface peer-group REMOTE
 !
 address-family ipv6 unicast
  network fc23:1::2/64
  network fc23:2::2/64
  neighbor REMOTE activate
 exit-address-family
exit

exit
write memory
EOS
KERNEL_PATTERN="menuentry '(Ubuntu, with Linux [0-9]+.[0-9]+.[0-9]+.mptcp)'"
KERNEL_NAME=$(cat /boot/grub/grub.cfg | grep -E "$KERNEL_PATTERN" | sed -r "s/^.*$KERNEL_PATTERN.*$/\1/")
sed -i "s/GRUB_DEFAULT=0/GRUB_DEFAULT=\"$KERNEL_NAME\"/g" /etc/default/grub
update-grub

echo "net.mptcp.mptcp_path_manager=fullmesh" >>/etc/sysctl.conf

reboot
