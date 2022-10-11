#!/bin/bash

set -e

if test "$#" -ne 9; then
	echo "Usage: setup.sh loadgen-host dut/vm-host timer-host evaluator-host vm-mode dut-app boot-mode dut-image measurement-time"
	exit
fi

LOADGEN=$1
DUT=$2
TIMER=$3
EVALUATOR=$4
VM_MODE=$5
DUT_APP=$6
BOOT_MODE=$7
DUT_OS=$8
MEASUREMENT_TIME=$9

EVALUATOR_IMAGE="debian-bullseye-evaluator@2021-08-22T03:12:23+00:00"
LOADGEN_IMAGE="debian-buster@2021-08-17T01:07:22+00:00"
TIMER_IMAGE="debian-buster@2021-08-17T01:07:22+00:00"

if ! [[ "$9" =~ ^[0-9]+$ ]]
then
	echo "measurement-time must be int"
	exit
else
	echo "measurement-time: $MEASUREMENT_TIME seconds"
fi
python -c "import yaml; l = yaml.full_load(open('global-vars.yml', 'r')); l['measurement_time'] = $MEASUREMENT_TIME; yaml.dump(l, open('global-vars-gen.yml', 'w'))"

if [ "$VM_MODE" == "vm" ]; then
	echo "DuT runs in VM"
	VM_HOST=$2
	DUT="$2-vm1"
elif [ "$VM_MODE" == "no-vm" ] ; then
	echo "DuT runs bare-metal"
else
	echo "vm-mode allowed values: vm | no-vm"
	exit
fi
python -c "import yaml; l = yaml.full_load(open('global-vars-gen.yml', 'r')); l['vm_mode'] = '$VM_MODE'; l['boot_mode'] = '$BOOT_MODE'; yaml.dump(l, open('global-vars-gen.yml', 'w'))"

if [ "$DUT_APP" == "dpdk-suricata" ] ; then
	echo "DuT runs dpdk suricata app"
elif [ "$DUT_APP" == "af-suricata" ] ; then
	echo "DuT runs suricata using the AF_PACKET API"
elif [ "$DUT_APP" == "dpdk-l2fwd-cat" ] ; then
	echo "DuT runs dpdk l2fwd-cat example app"
elif [ "$DUT_APP" == "dpdk-l2fwd" ] ; then
        echo "DuT runs dpdk l2fwd example app"
elif [ "$DUT_APP" == "ixy-l2fwd" ] ; then
	echo "DuT runs ixy"
elif [ "$DUT_APP" == "snabb-l2fwd" ] ; then
	echo "DuT runs snabb forwarder"
else
	echo "allowed values: dpdk-suricata | af-suricata | dpdk-l2fwd-cat | ixy-l2fwd | snabb-l2fwd"
	exit
fi
python -c "import yaml; l = yaml.full_load(open('global-vars-gen.yml', 'r')); l['dut_app'] = '$DUT_APP'; yaml.dump(l, open('global-vars-gen.yml', 'w'))"

python -c "import yaml; l = yaml.full_load(open('global-vars-gen.yml', 'r')); l['loadgen'] = '$LOADGEN'; yaml.dump(l, open('global-vars-gen.yml', 'w'))"


# mce=ignore_ce
# recommended by https://access.redhat.com/sites/default/files/attachments/201501-perf-brief-low-latency-tuning-rhel7-v1.1.pdf
# might cause periodic latency spikes if enabled

# audit=0
# recommended by https://access.redhat.com/sites/default/files/attachments/201501-perf-brief-low-latency-tuning-rhel7-v1.1.pdf
# may cause latency under load

# idle=poll
# recommended by https://access.redhat.com/sites/default/files/attachments/201501-perf-brief-low-latency-tuning-rhel7-v1.1.pdf
# keeps processors at their maximum frequency and c-state

# skew_tick=1
# recommended by http://people.redhat.com/jmario/docs/201501-perf-brief-low-latency-tuning-rhel7-v2.0.pdf
# should only be enabled if running jitter sensitive (HPC/RT) workloads

# intel_pstate=disable
# recommended by http://people.redhat.com/jmario/docs/201501-perf-brief-low-latency-tuning-rhel7-v2.0.pdf

# nosoftlockup
# recommended by http://people.redhat.com/jmario/docs/201501-perf-brief-low-latency-tuning-rhel7-v2.0.pdf

# msr.allow_writes
# allow msr writes used for Intel CAT

if [ "$BOOT_MODE" == "optimized" ]; then
	if [ "$VM_MODE" == "vm" ]; then
		BOOT_VM_HOST="nohz=on isolcpus=1,2,3 nohz_full=1,2,3 rcu_nocbs=1,2,3 apparmor=0"
	else
		BOOT_VM_HOST="apparmor=0"
	fi
	BOOT="nohz=on isolcpus=1,2,3 nohz_full=1,2,3 rcu_nocbs=1,2,3"
	BOOTPARAM="irqaffinity=0 tsc=reliable nmi_watchdog=0 random.trust_cpu=on intel_idle.max_cstate=0 mce=ignore_ce audit=0 idle=poll skew_tick=1 intel_pstate=disable nosoftlockup console=tty0 console=ttyS0,115200 nosmt rcu_nocb_poll msr.allow_writes=on iommu=pt"
elif [ "$BOOT_MODE" == "regular" ] ; then
	BOOT_VM_HOST=""
	BOOT=""
	BOOTPARAM="random.trust_cpu=on"
elif [ "$BOOT_MODE" == "energysaving" ] ; then
	if [ "$VM_MODE" == "vm" ]; then
		BOOT_VM_HOST="nohz=on isolcpus=1,2,3 nohz_full=1,2,3 rcu_nocbs=1,2,3 apparmor=0"
	else
		BOOT_VM_HOST="apparmor=0"
	fi
	BOOT="nohz=on isolcpus=1,2,3 nohz_full=1,2,3 rcu_nocbs=1,2,3"
	BOOTPARAM="irqaffinity=0 tsc=reliable nmi_watchdog=0 random.trust_cpu=on mce=ignore_ce audit=0 skew_tick=1 nosoftlockup console=tty0 console=ttyS0,115200"
else
	echo "boot-mode allowed values: regular | optimized | energysaving"
	exit
fi
DUT_BOOTPARAM="$BOOT $BOOTPARAM"
echo "DuT boot parameter: $DUT_BOOTPARAM"

if [ "$DUT_OS" == "bullseye-default" ]; then
	DUT_IMAGE="debian-bullseye@2021-12-21T02:29:06+00:00"
elif [ "$DUT_OS" == "bullseye-rt" ] ; then
	DUT_IMAGE="debian-bullseye-rt@2021-12-21T02:33:45+00:00"
elif [ "$DUT_OS" == "bullseye-nohz" ] ; then
	DUT_IMAGE="debian-bullseye-nohz@2021-12-21T04:04:35+00:00"
else
	echo "dut-os allowed values: bullseye-default | bullseye-rt | bullseye-nohz"
	exit
fi

echo "DuT OS: $DUT_IMAGE"
python -c "import yaml; l = yaml.full_load(open('global-vars-gen.yml', 'r')); l['dut_image'] = '$DUT_IMAGE'; yaml.dump(l, open('global-vars-gen.yml', 'w'))"

# in the best case, the hosts are already free
echo "free hosts (-force!)"
pos allocations free "$LOADGEN"
pos allocations free "$TIMER"
pos allocations free "$EVALUATOR"
if [ "$VM_MODE" == "vm" ]; then
	pos allocations free "$VM_HOST"
else
	pos allocations free "$DUT"
fi

# allocate all hosts for ONE experiment
echo "allocate hosts"
ALLOCATE="$LOADGEN $TIMER"
if [ "$VM_MODE" == "vm" ]; then
	ALLOCATE="$ALLOCATE $VM_HOST"
else
	ALLOCATE="$ALLOCATE $DUT"
fi
pos allocations allocate $ALLOCATE --duration 240
pos allocations allocate $EVALUATOR --duration 240
pos allocations set_variables "$LOADGEN" --as-global global-vars-gen.yml
pos allocations set_variables "$LOADGEN" --as-loop loop-vars.yml

if [ "$VM_MODE" == "vm" ]; then
	pos nodes spawn_vm "$VM_HOST" -c 1
	pos allocations add "$VM_HOST" "$DUT" --duration 240
fi

# use roles
pos roles add upwarm-$LOADGEN $LOADGEN $DUT
pos roles add cordre-$LOADGEN $LOADGEN $TIMER

echo "load experiment variables"
pos allocations set_variables "$LOADGEN" 'loadgen/local.yml'
if [ "$VM_MODE" == "vm" ]; then
	pos allocations set_variables "$DUT" 'dut/local-vm.yml'
	pos allocations set_variables "$VM_HOST" 'dut/local-vm.yml'
else
	pos allocations set_variables "$DUT" 'dut/local-no-vm.yml'
fi
pos allocations set_variables "$TIMER" 'timer/local.yml'
pos allocations set_variables "$EVALUATOR" 'evaluator/local.yml'

pos nodes bootparameter "$DUT" $DUT_BOOTPARAM
if [ "$VM_MODE" == "vm" ]; then
	VM_HOST_BOOTPARAM="$BOOT_VM_HOST $BOOTPARAM intel_iommu=on"
	pos nodes bootparameter "$VM_HOST" $VM_HOST_BOOTPARAM
fi

echo "set images to:"
echo "   Loadgen:   $LOADGEN_IMAGE"
echo "   DuT:       $DUT_IMAGE"
echo "   Timer:     $TIMER_IMAGE"
echo "   Evaluator: $EVALUATOR_IMAGE"
pos nodes image "$LOADGEN" "$LOADGEN_IMAGE"
pos nodes image "$DUT" "$DUT_IMAGE"
pos nodes image "$TIMER" "$TIMER_IMAGE"
pos nodes image "$EVALUATOR" "$EVALUATOR_IMAGE"
if [ "$VM_MODE" == "vm" ]; then
	pos nodes image "$VM_HOST" "$DUT_IMAGE"
fi

if [ "$VM_MODE" == "vm" ]; then
	echo "reset $VM_HOST"
	pos nodes reset "$VM_HOST"
	echo "$VM_HOST booted successfully"
	echo "push config files to $VM_HOST"
	pos nodes copy "$VM_HOST" vm-sriov/net.xml
	pos nodes copy "$VM_HOST" vm-sriov/net7.xml
	pos nodes copy "$VM_HOST" vm-sriov/net8.xml
	pos nodes copy "$VM_HOST" vm-sriov/passthrough7.xml
	pos nodes copy "$VM_HOST" vm-sriov/passthrough8.xml
	echo "execute userscript on $VM_HOST..."
	pos commands launch -i vm-sriov/prepare_vmhost.sh "$VM_HOST"
	echo "$VM_HOST prepared for starting vms"
fi

echo "reboot experiment hosts..."
# run reset blocking in background and wait for processes to end before continuing
{ pos nodes reset "$LOADGEN"; echo "$LOADGEN booted successfully"; } &
{ pos nodes reset "$DUT"; echo "$DUT booted successfully"; } &
{ pos nodes reset "$TIMER"; echo "$TIMER booted successfully"; } &
{ pos nodes reset "$EVALUATOR"; echo "$EVALUATOR booted successfully"; } &
wait

#echo "deploy files..."
pos nodes copy "$DUT" set_irq_affinity
#if [ "$BOOT_MODE" == "optimized" ]; then
#	pos commands launch --infile dut-irqaffinity.sh --no-logging --blocking "$DUT"; echo "$DUT bound irq of mgmt interface to core 0";
#fi

if [ "$VM_MODE" == "vm" ]; then
	./run.sh $LOADGEN $VM_HOST $TIMER $EVALUATOR $VM_MODE $DUT_APP $BOOT_MODE
else
	./run.sh $LOADGEN $DUT $TIMER $EVALUATOR $VM_MODE $DUT_APP $BOOT_MODE
fi
