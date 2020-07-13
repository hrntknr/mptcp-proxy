#!/bin/bash -eu
echo "net.ipv6.conf.all.forwarding=1" >>/etc/sysctl.conf
sysctl -p
sed -i 's/bgpd=no/bgpd=yes/g' /etc/frr/daemons
systemctl restart frr
vtysh <<EOS
configure terminal

router bgp 65008
 bgp router-id 192.168.100.8
 neighbor REMOTE peer-group
 neighbor REMOTE remote-as external
 neighbor REMOTE capability extended-nexthop
 neighbor enp3s0 interface peer-group REMOTE
 !
 address-family ipv6 unicast
  network fc28::2/64
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

cat <<EOS >/etc/netplan/99-custom.yaml
network:
  version: 2
  tunnels:
    tun0:
      mode: ip6ip6
      local: fc28::2
      remote: fc13::1
      addresses:
        - fc10::1/128
EOS
netplan apply -f

while [ 1 ]; do
  sleep 1
  if [ "$(cat /sys/class/net/tun0/carrier)" = "0" ]; then
    continue
  fi
  break
done

reboot
