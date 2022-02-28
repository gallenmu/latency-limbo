#!/bin/bash

set -e
set -x

echo "129.187.10.100 debian.mirror.lrz.de" >> /etc/hosts
DEBIAN_FRONTEND=noninteractive apt-get update --allow-releaseinfo-change
DEBIAN_FRONTEND=noninteractive apt-get install -y ethtool intel-cmt-cat

# needed for cat tool
modprobe msr

pqos -R
pqos -a "llc:1=1;llc:2=0,2,3"
pqos -e "llc:1=0xff;llc:2=0xf00"
pqos -s

echo 'cat allocation done'
