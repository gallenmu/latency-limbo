#!/bin/bash

# exit on error
set -e
# log every command
set -x

apt-get update --allow-releaseinfo-change
DEBIAN_FRONTEND=noninteractive apt-get install -y postgresql postgresql-client parallel python3-pip texlive-full zstd \
	python3-yaml

python3 -m pip install pypacker

REPO_FOLDER="/root/experiment-script"
git clone https://github.com/gallenmu/latency-limbo $REPO_FOLDER
cd $REPO_FOLDER
git checkout suricata
