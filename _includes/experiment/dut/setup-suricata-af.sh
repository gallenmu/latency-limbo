#!/bin/bash

set -e
set -x

apt-get update
apt-get install -y build-essential libpcap-dev   \
	libnet1-dev libyaml-0-2 libyaml-dev pkg-config zlib1g zlib1g-dev \
	libcap-ng-dev libcap-ng0 make libmagic-dev         \
	libgeoip-dev liblua5.1-dev libhiredis-dev libevent-dev \
	python3-yaml rustc cargo libpcre2-dev meson ninja-build \
	python3-pyelftools libjansson-dev cbindgen

# enable links
PORT_RX="$(pos_get_variable port/rx)"
PORT_TX="$(pos_get_variable port/tx)"

ip link set dev $PORT_RX up
ip link set dev $PORT_TX up

# setup suricata
git clone https://github.com/gallenmu/latency-limbo /root/suricata
cd /root/suricata
git checkout dpdk-21.11
# TODO fix commit id
git clone https://github.com/OISF/libhtp
cd /root/suricata/libhtp
# TODO fix commit id
./autogen.sh
./configure
cd /root/suricata
./autogen.sh
./configure --enable-af
make -j2
make install
ldconfig
