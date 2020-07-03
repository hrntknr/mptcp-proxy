#!/bin/bash -eu
cd $(dirname $0)

. config.sh

for host in "${targets[@]}"; do
  if [ "$(virsh list | awk '{ print $2 }' | grep -e ^$host$)" ]; then
    virsh destroy $host
  fi

  if [ "$(virsh list --all | awk '{ print $2 }' | grep -e ^$host$)" ]; then
    virsh undefine $host
  fi

  if [ -f $IMG_DIR/$host.qcow2 ]; then
    rm $IMG_DIR/$host.qcow2
  fi

  if [ -f $IMG_DIR/${host}_config.qcow2 ]; then
    rm $IMG_DIR/${host}_config.qcow2
  fi
done
