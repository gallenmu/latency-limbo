#!/bin/bash

REPEAT=$(pos_get_variable -l repeat)
PACKETRATE=$(pos_get_variable -l packetrate)
CONFIG=$(pos_get_variable -l config)
IRQRECORDING=$(pos_get_variable -l irqrecording)
DISABLENIC=$(pos_get_variable -l disablenic)

ENIC=$(pos_get_variable enic)

MEASUREMENT_TIME=$(pos_get_variable -g measurement_time)
LOADGEN=$(pos_get_variable -g loadgen)

pos_sync
echo "starting experiment: $(date)"

if [ ! $IRQRECORDING -eq 0 ]; then
	sleep 2
	echo "start irq recording"
	pos_run -l irql2fwd -- taskset -c 2 /root/experiment-script/irq/irqrecorder.py
	sleep 2
else
	echo "no irq recording"
fi

pos_run -l l2fwdrun -- bash -c "/root/dpdk-21.11/build/examples/dpdk-l2fwd-cat -l 1 -n 4 -- --l3ca='0xf00@(0,2-3),0x0ff@(1)'"
sleep 30

echo "waiting for upwarm $(date)"
pos_sync -t warmup -l upwarm-$LOADGEN
echo "received upwarm $(date)"

# avoid disturbance by disabling eno1 during the latency measurement
if [ ! $DISABLENIC -eq 0 ]; then
	echo "disable nic"
	ip link set dev "$ENIC" down
	sleep $(($MEASUREMENT_TIME+120))
	ip link set dev "$ENIC" up
	sleep 15
else
	sleep $(($MEASUREMENT_TIME+120))
fi

pos_sync

pos_kill -l l2fwdrun

if [ ! $IRQRECORDING -eq 0 ]; then
	pos_kill -l irql2fwd
	sleep 2
	pos_upload -l irqrecorder.csv
fi

echo "killed dpdk-l2fwd-cat: $(date)"
sleep 2

