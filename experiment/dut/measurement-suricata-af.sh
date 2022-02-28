#!/bin/bash

REPEAT=$(pos_get_variable -l repeat)
PACKETRATE=$(pos_get_variable -l packetrate)
CONFIG=$(pos_get_variable -l config)
IRQRECORDING=$(pos_get_variable -l irqrecording)
DISABLENIC=$(pos_get_variable -l disablenic)

MEASUREMENT_TIME=$(pos_get_variable -g measurement_time)
LOADGEN=$(pos_get_variable -g loadgen)

pos_sync
echo "starting experiment: $(date)"

# start recording irqs
if [ ! $IRQRECORDING -eq 0 ]; then
        sleep 2
        echo "start irq recording"
	pos_run -l irqrecord -- taskset -c 0 /root/experiment-script/irq/irqrecorder.py
	sleep 2
else
        echo "no irq recording"
fi

pos_run -l suricatarecord -- suricata -c /root/experiment-script/config/$CONFIG --af-packet
sleep 22

echo "waiting for upwarm $(date)"
pos_sync -t warmup -l upwarm-$LOADGEN
echo "received upwarm $(date)"

pos_kill -l suricatarecord
pos_sync

if [ ! $IRQRECORDING -eq 0 ]; then
	pos_kill -l irqrecord
	sleep 2
	pos_upload -l irqrecorder.csv
fi

echo "killed suricata: $(date)"
sleep 2

