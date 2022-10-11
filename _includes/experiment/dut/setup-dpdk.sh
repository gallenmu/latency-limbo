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
DPDK_COMMIT="$(pos_get_variable dpdk/commit)"
VM_MODE="$(pos_get_variable -g vm_mode)"

# setup dpdk
cd /root
git clone https://github.com/gallenmu/dpdk-1 /root/dpdk-21.11
cd /root/dpdk-21.11
git checkout $DPDK_COMMIT

if [ "$VM_MODE" == "vm" ]; then                                                 
        echo "vm mode: disable cat initialization in l2fwd-cat"
	sed '160,171d' examples/l2fwd-cat/l2fwd-cat.c > examples/l2fwd-cat/temp.c
	rm examples/l2fwd-cat/l2fwd-cat.c
	mv examples/l2fwd-cat/temp.c examples/l2fwd-cat/l2fwd-cat.c
fi

meson -Ddisable_drivers=gpu/*,baseband/*,event/*,vdpa/*,regex/*,compress/*,crypto/*,raw/*,dma/cnxk,dma/dpaa,dma/hisilicon,mempool/cnxk,mempool/dpaa,mempool/dpaa2,mempool/octeontx,mempool/octeontx2,net/a*,net/b*,net/c*,net/d*,net/ena,net/enetc,net/enetfec,net/enic,net/f*,net/h*,net/k*,net/l*,net/m*,net/n*,net/o*,net/p*,net/q*,net/s*,net/t*,net/v*,common/dpaax,common/cnxk,common/octeontx,common/octeontx2,common/sfc_efx,common/cpt -Dexamples=l3fwd,l2fwd,l2fwd-cat build
cd /root/dpdk-21.11/build
ninja install
echo 512 > /sys/devices/system/node/node0/hugepages/hugepages-2048kB/nr_hugepages

# load driver
if [ "$VM_MODE" == "vm" ]; then
	echo "vm mode: vm enabled"
	modprobe uio_pci_generic
	/root/dpdk-21.11/usertools/dpdk-devbind.py --bind=uio_pci_generic $RX_PCI_ADDR $TX_PCI_ADDR
else
	echo "vm mode: vm disabled"
	modprobe vfio-pci
	/root/dpdk-21.11/usertools/dpdk-devbind.py --bind=vfio-pci $RX_PCI_ADDR $TX_PCI_ADDR
fi


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

if [ "$VM_MODE" == "vm" ]; then
	echo "CAT not possible on VM directly"
else
	echo "reset CAT, necessary once to run dpdk-cat-fwd"
	pqos -R
fi
