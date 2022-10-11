#!/bin/bash

# exit on error
set -e
# log every command
set -x

apt update
apt install -y zstd

# load some variables
PORT_TX=$(pos_get_variable portno/tx)
PORT_RX=$(pos_get_variable portno/rx)
SRC_MAC=$(pos_get_variable dst/srcmac)
DST_MAC=$(pos_get_variable dst/dstmac)
L4_DSTPORT=$(pos_get_variable l4param/dstport)
FLOW_NUM=$(pos_get_variable flownum)
BURST=$(pos_get_variable burst)
GIT_REPO=$(pos_get_variable -g moongen/repo)
GIT_BRANCH=$(pos_get_variable -g moongen/branch)
GIT_COMMIT=$(pos_get_variable -g moongen/commit)
LOADGEN=moongen
POS_SERVER=$(pos_get_variable pos_server)
MEASUREMENT_TIME=$(pos_get_variable -g measurement_time)

cd ~

# prepare loadgen
if [[ ! -e "$LOADGEN" ]]
then
	git clone --branch "$GIT_BRANCH" --recurse-submodules --jobs 4 "$GIT_REPO" "$LOADGEN"
fi
cd "$LOADGEN"
git checkout "$GIT_COMMIT"
/root/$LOADGEN/build.sh
/root/$LOADGEN/bind-interfaces.sh
/root/$LOADGEN/setup-hugetlbfs.sh

echo 'setup finished'
