#!/bin/bash -eu
cd $(dirname $0)

if [ $# != 1 ]; then
  MOUNT_ROOT=$(dirname $(pwd))
  IMG_DIR=$(pwd)/images
  CFG_DIR=$(pwd)/configs
  DISK_SIZE=10G

  targets=(l3sw1 client lb1 server1 server2)
  networks=(mgmt client_1 client_2 lb1 server1 server2)
else
  case "$1" in
  l3sw1) EXTRA_NET="--network network:client_1 --network network:client_2 --network network:lb1 --network network:server1 --network network:server2 --network type=direct,source=ens1f1,source_mode=vepa" ;;
  client) EXTRA_NET="--network network:$1_1 --network network:$1_2" ;;
  lb1) EXTRA_NET="--network network:$1" ;;
  proxy[1-2]) EXTRA_NET="--network network:$1" ;;
  server[1-2]) EXTRA_NET="--network network:$1" ;;
  *) EXTRA_NET="" ;;
  esac
fi
