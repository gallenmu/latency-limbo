#!/bin/bash

# exit on error
set -e
# log every command
set -x

MEASUREMENT_TIME=$(pos_get_variable -g measurement_time)
TIMEOUT_AMOUNT=$(($MEASUREMENT_TIME+90))

PORT_NO_RX=$(pos_get_variable portno/rx)
PORT_NO_TX=$(pos_get_variable portno/tx)

LOADGEN=$(pos_get_variable -g loadgen)

# install moongen
MOONGEN=moongen

pos_sync
echo "starting experiment $(date)"

echo "waiting for cordre $(date)"
pos_sync -t record -l cordre-$LOADGEN
echo "received cordre $(date)"

# start dumping interfaces
pos_run -l moonsniff -- /root/$MOONGEN/build/MoonGen /root/$MOONGEN/examples/moonsniff/sniffer.lua $PORT_NO_RX $PORT_NO_TX --capture --time $TIMEOUT_AMOUNT --snaplen 64
echo "recording pcaps $(date)"

sleep 10 # to be save recording has actually started

pos_wait -l moonsniff
echo "end recording pcaps $(date)"

pos_sync

zstdmt -13 --rm latencies-pre.pcap
zstdmt -13 --rm latencies-post.pcap
sleep 2
pos_upload -l latencies-pre.pcap.zst
pos_upload -l latencies-post.pcap.zst
sleep 5
rm latencies-pre.pcap.zst
rm latencies-post.pcap.zst
sleep 2
