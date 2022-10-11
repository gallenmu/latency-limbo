#!/bin/bash

set -e
set -x

# checkout experiment files, e.g. irqrecorder
git clone https://github.com/gallenmu/latency-limbo /root/experiment-script
cd /root/experiment-script
git checkout suricata
# TODO fix commit id
