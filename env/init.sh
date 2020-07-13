#!/bin/bash -eu
cd $(dirname $0)

. config.sh

if [ ! -d $IMG_DIR ]; then
  mkdir -p $IMG_DIR
fi

if [ ! -f $IMG_DIR/cloudimg.qcow2 ]; then
  if [ ! -f $IMG_DIR/cloudimg.img ]; then
    wget https://cloud-images.ubuntu.com/bionic/current/bionic-server-cloudimg-amd64.img -O $IMG_DIR/cloudimg.img
  fi
  qemu-img create -b $IMG_DIR/cloudimg.img -F qcow2 -f qcow2 $IMG_DIR/cloudimg.qcow2 $DISK_SIZE
fi

for net in "${networks[@]}"; do
  if [ ! "$(virsh net-list --all | awk '{ print $1 }' | grep -e ^$net$)" ]; then
    virsh net-define $CFG_DIR/net/$net.xml
    virsh net-autostart $net
  fi

  if [ ! "$(virsh net-list | awk '{ print $1 }' | grep -e ^$net$)" ]; then
    virsh net-start $net
  fi
done

for host in "${targets[@]}"; do
  if [ ! -f $IMG_DIR/$host.qcow2 ]; then
    cp $IMG_DIR/cloudimg.qcow2 $IMG_DIR/$host.qcow2
  fi

  if [ ! -f $IMG_DIR/${host}_config.qcow2 ]; then
    userdata=$(mktemp)
    python3 make-mime.py -a $CFG_DIR/vm/$host/config.yml:cloud-config -a $CFG_DIR/vm/$host/init.sh:x-shellscript >$userdata
    cloud-localds -v --network-config=$CFG_DIR/vm/$host/network_config.yml $IMG_DIR/${host}_config.qcow2 $userdata
    rm $userdata
  fi

  if [ ! "$(virsh list --all | awk '{ print $2 }' | grep -e ^$host$)" ]; then
    . config.sh $host
    VM_XML=$(sh -c \
      "virt-install \
      --name $host \
      --virt-type kvm \
      --ram 4096 \
      --vcpus 2 \
      --disk path=$IMG_DIR/$host.qcow2,device=disk \
      --disk path=$IMG_DIR/${host}_config.qcow2,device=cdrom \
      --filesystem source=$MOUNT_ROOT,target=mptcp_proxy \
      --os-type linux \
      --os-variant debian9 \
      --network network:mgmt \
      $EXTRA_NET \
      --console pty,target_type=serial \
      --nographics \
      --noautoconsole \
      --boot useserial=on \
      --print-xml")
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface" -t elem -n driver <<<$VM_XML)
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface/driver" -t attr -n name -v vhost <<<$VM_XML)
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface/driver" -t attr -n queues -v 4 <<<$VM_XML)
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface/driver" -t elem -n host <<<$VM_XML)
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface/driver/host" -t attr -n gso -v off <<<$VM_XML)
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface/driver/host" -t attr -n tso4 -v off <<<$VM_XML)
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface/driver/host" -t attr -n tso6 -v off <<<$VM_XML)
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface/driver/host" -t attr -n ecn -v off <<<$VM_XML)
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface/driver/host" -t attr -n ufo -v off <<<$VM_XML)
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface/driver" -t elem -n guest <<<$VM_XML)
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface/driver/guest" -t attr -n tso4 -v off <<<$VM_XML)
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface/driver/guest" -t attr -n tso6 -v off <<<$VM_XML)
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface/driver/guest" -t attr -n ecn -v off <<<$VM_XML)
    VM_XML=$(xmlstarlet ed -s "/domain/devices/interface/driver/guest" -t attr -n ufo -v off <<<$VM_XML)
    VM_XML_FILE=$(mktemp)
    echo "$VM_XML" >$VM_XML_FILE
    virsh define $VM_XML_FILE
    virsh start $host
  fi
done
