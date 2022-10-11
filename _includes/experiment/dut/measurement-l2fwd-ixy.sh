#!/bin/bash

REPEAT=$(pos_get_variable -l repeat)
PACKETRATE=$(pos_get_variable -l packetrate)
CONFIG=$(pos_get_variable -l config)
RX_PCI_ADDR="$(pos_get_variable pciadr/rx)"
TX_PCI_ADDR="$(pos_get_variable pciadr/tx)"

pos_sync
echo "starting experiment: $(date)"

# start recording irqs
#pos_run -l snortrunirq -- taskset -c 2 /root/experiment-script/irqrecorder.py
#sleep 2

pos_run -l snortrun -- bash -c "taskset -c 1 /root/ixy/ixy-fwd 0000:$RX_PCI_ADDR 0000:$TX_PCI_ADDR"
sleep 22

echo "started dpdk-l2fwd-cat: $(date)"
pos_sync
echo "warming up"
sleep 1
pos_sync
echo "begin measurement"
sleep 1
pos_sync
echo "sync one"
sleep 1
pos_sync
echo "sync two"
sleep 1

pos_kill -l snortrun
#pos_kill -l snortrunirq
sleep 2
pos_sync
#pos_upload -l irqrecorder.csv

echo "killed dpdk-l2fwd-cat: $(date)"
sleep 2

