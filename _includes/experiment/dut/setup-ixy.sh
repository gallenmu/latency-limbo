#!/bin/bash

set -e
set -x

apt-get update
apt-get install -y build-essential libpcap-dev   \
	libnet1-dev libyaml-0-2 libyaml-dev pkg-config zlib1g zlib1g-dev \
	libcap-ng-dev libcap-ng0 make libmagic-dev         \
	libgeoip-dev liblua5.1-dev libhiredis-dev libevent-dev \
	python3-yaml rustc cargo libpcre2-dev meson ninja-build \
	python3-pyelftools libjansson-dev cbindgen intel-cmt-cat

# necessary to use pqos
modprobe msr

# get PCI addresses (04:00.0, 04:00.1)
RX_PCI_ADDR="$(pos_get_variable pciadr/rx)"
TX_PCI_ADDR="$(pos_get_variable pciadr/tx)"

git clone https://github.com/gallenmu/latency-limbo /root/experiment-script
cd /root/experiment-script
git checkout suricata

# bind vfio
/root/experiment-script/scripts/vfio-pci-bind.sh $RX_PCI_ADDR
/root/experiment-script/scripts/vfio-pci-bind.sh $TX_PCI_ADDR

# setup snabb
git clone https://github.com/emmericp/ixy /root/ixy
cd /root/ixy
./setup-hugetlbfs.sh
cmake .
make

# setup dpdk
#cd /root
#wget https://fast.dpdk.org/rel/dpdk-21.11.tar.xz
#tar xf dpdk-21.11.tar.xz
#cd /root/dpdk-21.11
#meson -Dexamples=l3fwd,l2fwd,l2fwd-cat build
#cd /root/dpdk-21.11/build
#ninja install
#echo 8192 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages

# load driver
#modprobe vfio-pci
#/root/dpdk-21.11/usertools/dpdk-devbind.py --bind=vfio-pci $RX_PCI_ADDR $TX_PCI_ADDR

#modprobe uio
#modprobe uio_pci_generic
#/root/dpdk-21.11/usertools/dpdk-devbind.py --bind=uio_pci_generic $RX_PCI_ADDR $TX_PCI_ADDR

# install ice driver (to get ddp for e810 NICs)
#cd /root
#tar -xzf /root/experiment-script/ice/ice-1.7.16.tar.gz
#cd /root/ice-1.7.16/src
#make -j2
#make install
#rmmod ice
#modprobe ice

sysctl vm.stat_interval=3600
sysctl -w kernel.watchdog=0

#echo "reset CAT, necessary once to run dpdk-cat-fwd"
#pqos -R
