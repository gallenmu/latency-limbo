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

# setup suricata
git clone https://github.com/gallenmu/suricata /root/suricata
cd /root/suricata
git checkout d3816127b95a8d72303fb054f6cc91fa3ebc1a85 # on dpdk-21.11 branch

git clone https://github.com/OISF/libhtp
cd /root/suricata/libhtp
git checkout 966c400f01d43ed862e3243b4531295a9ddfa767

./autogen.sh
./configure
cd /root/suricata
./autogen.sh
./configure --enable-dpdk --disable-python
make -j2
make install
ldconfig
