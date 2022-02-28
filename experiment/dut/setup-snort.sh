#!/bin/bash

set -e
set -x

apt-get update
apt-get install -y build-essential libpcap-dev   \
	libnet1-dev libyaml-0-2 libyaml-dev pkg-config zlib1g zlib1g-dev \
	libcap-ng-dev libcap-ng0 make libmagic-dev         \
	libgeoip-dev liblua5.1-dev libhiredis-dev libevent-dev \
	python3-yaml rustc cargo libpcre2-dev meson ninja-build \
	python3-pyelftools libjansson-dev cbindgen \
	libluajit-5.1-dev libpcap-dev \
	libpcre3-dev zlib1g-dev pkg-config libhwloc-dev cmake liblzma-dev \
	openssl libssl-dev cpputest libsqlite3-dev libtool git autoconf \
	bison flex asciidoc source-highlight \
	libgoogle-perftools-dev


# setup libdaq
git clone https://github.com/snort3/libdaq /root/libdaq
cd /root/libdaq
git checkout 55f98893a8b2e31cf9f806c775c011f05845f2de
./bootstrap
./configure --enable-tsc-clock --disable-dump-module --disable-ipfw-module --disable-ipq-module --disable-nfq-module --disable-pcap-module --disable-netmap-module --disable-afpacket-module --enable-static --disable-shared --disable-savefile-module --disable-trace-module --enable-dpdk-module --prefix=/opt/snort

# setup snort3
git clone https://pos:glpat-mc9ScyFq2ZpegTPJaccG@gitlab.lrz.de/nokia-university-donation/snort3 /root/snort3
cd /root/snort3
#git checkout dpdk-21.11
# TODO fix commit id
#git clone https://github.com/OISF/libhtp
#cd /root/suricata/libhtp
# TODO fix commit id
#./autogen.sh
#./configure
#cd /root/suricata
#./autogen.sh
#./configure --enable-dpdk --disable-python
#make -j2
#make install
#ldconfig
