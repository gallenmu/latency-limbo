#!/bin/bash

if test "$#" -ne 7; then
	echo "Usage: run.sh tester dut timer evaluator vm-mode daq-mode boot-mode"
	exit
fi

LOADGEN=$1
DUT=$2
TIMER=$3
EVALUATOR=$4
VM_MODE=$5
DAQ_MODE=$6
BOOT_MODE=$7

if [ "$VM_MODE" == "vm" ]; then
	VM_HOST=$2
	DUT="$2-vm1"
fi

if [ "$BOOT_MODE" == "optimized" ]; then
	echo "partition l3 cache on DuT..."
	if [ "$VM_MODE" == "vm" ]; then
		pos commands launch --infile dut/setup-cat-vm.sh --blocking "$VM_HOST"
		echo "$VM_HOST partitioned cache..."
	else
		pos commands launch --infile dut/setup-cat.sh --blocking "$DUT"
		echo "$DUT partitioned cache..."
	fi
else
	echo "no l3 cache partitioning"
fi

echo "deploy & run experiment scripts..."
sleep 2
{ pos commands launch --infile loadgen/setup.sh --blocking "$LOADGEN"; echo "$LOADGEN setup executed"; } &
if [ "$DAQ_MODE" == "dpdk-suricata" ] ; then
  { pos commands launch --infile dut/setup-repo.sh --blocking "$DUT";
    echo "$DUT cloned repo";
    pos commands launch --infile dut/setup-dpdk.sh --blocking "$DUT";
    echo "$DUT dpdk setup executed";
    pos commands launch --infile dut/setup-suricata.sh --blocking "$DUT";
    echo "$DUT suricata setup executed";
  } &
elif [ "$DAQ_MODE" == "af-suricata" ] ; then
  { pos commands launch --infile dut/setup-repo.sh --blocking "$DUT";
    echo "$DUT cloned repo";
    pos commands launch --infile dut/setup-suricata-af.sh --blocking "$DUT";
    echo "$DUT suricata af setup executed";
  } &
elif [ "$DAQ_MODE" == "dpdk-l2fwd-cat" ] ; then
  { pos commands launch --infile dut/setup-repo.sh --blocking "$DUT";
    echo "$DUT cloned repo";
    pos commands launch --infile dut/setup-dpdk.sh --blocking "$DUT";
    echo "$DUT dpdk setup executed";
  } &
elif [ "$DAQ_MODE" == "dpdk-l2fwd" ] ; then
  { pos commands launch --infile dut/setup-repo.sh --blocking "$DUT";
    echo "$DUT cloned repo";
    pos commands launch --infile dut/setup-dpdk.sh --blocking "$DUT";
    echo "$DUT dpdk setup executed";
  } &
elif [ "$DAQ_MODE" == "ixy-l2fwd" ] ; then
  { pos commands launch --infile dut/setup-ixy.sh --blocking "$DUT";
    echo "$DUT ixy setup executed";
  } &
elif [ "$DAQ_MODE" == "snabb-l2fwd" ] ; then
  { pos commands launch --infile dut/setup-snabb.sh --blocking "$DUT";
    echo "$DUT snabb setup executed";
  } &
fi
{ pos commands launch --infile timer/setup.sh --blocking "$TIMER"; echo "$TIMER setup executed"; } &
{ pos commands launch --infile evaluator/setup.sh --blocking "$EVALUATOR"; echo "$EVALUATOR setup executed"; } &
if [ "$VM_MODE" == "vm" ]; then
	echo "start vm-host script"
	{ pos commands launch --infile dut/setup-repo.sh --blocking "$VM_HOST"; echo "$VM_HOST host ready for evaluating..."; } &
fi
wait

{ pos commands launch --loop --infile loadgen/measurement.sh --blocking "$LOADGEN"; echo "$LOADGEN userscript executed"; } &
if [ "$DAQ_MODE" == "dpdk-suricata" ] ; then
  { pos commands launch --loop --infile dut/measurement-suricata.sh --blocking "$DUT"; echo "$DUT userscript executed"; } &
elif [ "$DAQ_MODE" == "af-suricata" ] ; then
  { pos commands launch --loop --infile dut/measurement-suricata-af.sh --blocking "$DUT"; echo "$DUT userscript executed"; } &
elif [ "$DAQ_MODE" == "dpdk-l2fwd-cat" ] ; then
  { pos commands launch --loop --infile dut/measurement-l2fwd-cat.sh --blocking "$DUT"; echo "$DUT userscript executed"; } &
elif [ "$DAQ_MODE" == "dpdk-l2fwd" ] ; then
  { pos commands launch --loop --infile dut/measurement-l2fwd.sh --blocking "$DUT"; echo "$DUT userscript executed"; } &
elif [ "$DAQ_MODE" == "ixy-l2fwd" ] ; then
  { pos commands launch --loop --infile dut/measurement-l2fwd-ixy.sh --blocking "$DUT"; echo "$DUT userscript executed"; } &
fi
{ pos commands launch --loop --infile timer/measurement.sh --blocking "$TIMER"; echo "$TIMER userscript executed"; } &
if [ "$VM_MODE" == "vm" ]; then
	echo "start vm-host script"
	{ pos commands launch --loop --infile dut/vm-host.sh --blocking "$VM_HOST"; echo "$VM_HOST userscript executed..."; } &
fi
wait

#echo "execute rdtsc measurement..."
#sleep 2
#pos commands launch --infile dut/rdtsc.sh --blocking "$DUT"; echo "$DUT rdtsc script executed";

RESULT_PATH="/srv/testbed/results/$(pos allocations show $DUT | jq --raw-output '.result_folder')/$TIMER/"
rsync -r -P $RESULT_PATH "$EVALUATOR:~/results"
IRQRESULT_PATH="/srv/testbed/results/$(pos allocations show $DUT | jq --raw-output '.result_folder')/$DUT/*.csv"
rsync -r -P $IRQRESULT_PATH "$EVALUATOR:~/results"
if [ "$VM_MODE" == "vm" ]; then
	IRQVMHOSTRESULT_PATH="/srv/testbed/results/$(pos allocations show $VM_HOST | jq --raw-output '.result_folder')/$VM_HOST/"
	rsync -r -P $IRQVMHOSTRESULT_PATH "$EVALUATOR:~/irqplotter/rawdata"
fi

pos commands launch --infile evaluator/evaluate.sh --blocking "$EVALUATOR"
echo "$EVALUATOR finished evaluating"
echo "results in folder: $(pos allocations show $EVALUATOR | jq --raw-output '.result_folder')"
