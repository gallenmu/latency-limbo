#!/bin/bash

BOOT_MODE=$(pos_get_variable -g boot_mode)

if [ "$BOOT_MODE" == "optimized" ]; then
	echo "boot mode: optimized"
	# bind rcu processes to core 0
	# recommended by https://access.redhat.com/documentation/en-us/red_hat_enterprise_linux/7/html-single/performance_tuning_guide/#sect-Red_Hat_Enterprise_Linux-Performance_Tuning_Guide-Configuration_suggestions-Configuring_kernel_tick_time
	for i in `pgrep rcu[^c]` ; do taskset -pc 0 $i ; done
else
	echo "boot mode: regular"
fi

set -e
set -x


# install dependencies
apt update
apt install -y virt-manager qemu-system pkg-config libvirt-dev python3-libvirt

apt install -y python3-pip
pip3 install virtualbmc

# Magic start
vbmcd

if [ "$BOOT_MODE" == "optimized" ]; then
	# activate virtual functions
	rmmod ixgbe
	modprobe ixgbe max_vfs=1
else
	:
fi

sleep 5 # magic sleep do not remove

ip link set up dev eno7
ip link set up dev eno8

# disable ipv6 to avoid pf chatting on vf connection
sysctl net.ipv6.conf.eno7.disable_ipv6=1
sysctl net.ipv6.conf.eno8.disable_ipv6=1

# configure VM
virsh net-define net.xml
virsh net-start net

if [ "$BOOT_MODE" == "optimized" ]; then
	virsh net-define passthrough7.xml
	virsh net-define passthrough8.xml
	virsh net-start passthrough7
	virsh net-start passthrough8
else
	virsh net-define net7.xml
	virsh net-define net8.xml
	virsh net-start net7
	virsh net-start net8
fi

IP="$(hostname -I)"
OCT3=$(echo ${IP} | tr "." " " | awk '{ print $3 }')
HEX=$(echo "obase=16; $OCT3" | bc)
MAC="52:54:00:$HEX:00:02"
if [ "$BOOT_MODE" == "optimized" ]; then
	virt-install --cpu host-passthrough --memory 16384 --vcpus=3 --cpuset=1-3 --boot=network --name vm --nodisks --network="network=net,mac=$MAC,model=virtio" --network="network=passthrough7,mac=52:54:00:8d:9d:ad,model=none" --network="network=passthrough8,mac=52:54:00:21:f8:29,model=none" --noautoconsole --graphics none --dry-run --controller="type=usb,model=none" --print-xml --console "pty,target_type=virtio" --cputune="vcpupin0.cpuset=1,vcpupin0.vcpu=0,vcpupin1.cpuset=2,vcpupin1.vcpu=1,vcpupin2.cpuset=3,vcpupin2.vcpu=2" > vm.xml
else
	virt-install --cpu host-passthrough --memory 16384 --vcpus=3 --cpuset=1-3 --boot=network --name vm --nodisks --network="network=net,mac=$MAC,model=virtio" --network="network=net7,mac=52:54:00:8d:9d:ad,model=virtio" --network="network=net8,mac=52:54:00:21:f8:29,model=virtio" --noautoconsole --graphics none --dry-run --controller="type=usb,model=none" --print-xml --console "pty,target_type=virtio" > vm.xml

fi
virsh define vm.xml

# configure virtual BMC
vbmc add --username ADMIN --password blockchain --port 6001 vm
vbmc start vm # starts only the vBMC NOT the VM itself

sleep 15
