#!/bin/bash

set -e
set -x

# checkout experiment files, e.g. irqrecorder
git clone https://pos2:glpat-2ggPB6QvzJJbmtg7-j66@gitlab.lrz.de/nokia-university-donation/measurement-script /root/experiment-script
cd /root/experiment-script
git checkout suricata
# TODO fix commit id
