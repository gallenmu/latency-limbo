#!/bin/bash

# exit on error
set -e
# log every command
set -x

# load some variables
PORT_TX=$(pos_get_variable portno/tx)
PORT_RX=$(pos_get_variable portno/rx)
SRC_MAC=$(pos_get_variable dst/srcmac)
DST_MAC=$(pos_get_variable dst/dstmac)
L4_DSTPORT=$(pos_get_variable l4param/dstport)
FLOW_NUM=$(pos_get_variable flownum)
BURST=$(pos_get_variable burst)
LOADGEN=moongen
POS_SERVER=$(pos_get_variable pos_server)
PACKET_RATE=$(pos_get_variable -l packetrate)
MEASUREMENT_TIME=$(pos_get_variable -g measurement_time)
LG=$(pos_get_variable -g loadgen)

pos_sync
echo "waiting for timer and dut $(date)"

echo "waiting for upwarm $(date)"
pos_sync -t warmup -l upwarm-$LG # sync with dut on warmup-phase
echo "received upwarm $(date)"

PACKET_AMOUNT=$(($PACKET_RATE*$MEASUREMENT_TIME))
TIMEOUT_AMOUNT=$(($MEASUREMENT_TIME+90))

# WARM-UP DUT
pos_run -l replay -- /root/$LOADGEN/build/MoonGen /root/$LOADGEN/examples/moonsniff/traffic-gen.lua --src-mac $SRC_MAC --dst-mac $DST_MAC --fix-packetrate $PACKET_RATE --packets $PACKET_AMOUNT --warm-up 30 --l4-dst $L4_DSTPORT --flows $FLOW_NUM --burst $BURST $PORT_TX $PORT_RX
sleep 15
echo "waiting for cordre $(date)"
pos_sync -t record -l cordre-$LG # sync with timer on record-phase
echo "received cordre $(date)"

pos_sync

pos_wait -l --timeout $TIMEOUT_AMOUNT replay
echo "moongen finished sending $(date)"
