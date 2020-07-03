#!/bin/bash -eu
cd $(dirname $0)

. config.sh

for net in "${networks[@]}"; do
  if [ "$(virsh net-list | awk '{ print $1 }' | grep -e ^$net$)" ]; then
    virsh net-destroy $net
  fi

  if [ "$(virsh net-list --all | awk '{ print $1 }' | grep -e ^$net$)" ]; then
    virsh net-undefine $net
  fi
done
