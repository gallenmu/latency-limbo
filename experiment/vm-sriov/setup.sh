#!/bin/bash

if test "$#" -lt 1; then
	echo "Usage: setup.sh vmhost"
	exit
fi

NODE=$1
POS=pos

echo "free hosts (--force!)"
$POS allocations free --force "$NODE"

echo "allocate hosts"
$POS allocations allocate "$NODE" --duration 180

echo "set bootparameter isolcpu, iommu"
$POS nodes bootparameter "$NODE" isolcpus=1,2 nohz_full=1,2 rcu_nocbs=1,2 irqaffinity=0 tsc=reliable nmi_watchdog=0 random.trust_cpu=on intel_idle.max_cstate=0 mce=ignore_ce audit=0 idle=poll skew_tick=1 intel_pstate=disable nosoftlockup intel_iommu=on

echo "set images"
#$POS nodes image "$NODE" "$IMAGE"
#$POS nodes image --staging "$NODE" debian-stretch-rt_2019-01-11T17:27:17+00:00
#$POS nodes image --staging "$NODE" debian-buster-rt_2019-01-11T22:01:31+00:00
$POS nodes image --staging "$NODE" debian-nohzbuster_2019-02-01T22:05:48+00:00

echo "reboot experiment hosts..."
$POS nodes reset "$NODE"
echo "$NODE booted successfully"

echo "register vm on $NODE"
$POS nodes spawn_vm "$NODE" -c 1

echo "push config files to host"
$POS nodes copy "$NODE" net.xml
$POS nodes copy "$NODE" passthrough7.xml
$POS nodes copy "$NODE" passthrough8.xml
$POS nodes copy "$NODE" vm.xml

echo "execute userscript on hosts..."
$POS commands launch -i prepare_vmhost.sh "$NODE"
echo "$NODE prepared for starting vms"

echo "script finished"
