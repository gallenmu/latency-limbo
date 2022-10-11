#!/bin/bash

set -x
set -e

NUM_CORES=$(pos_get_variable num_cores) #$(grep -c '^processor' /proc/cpuinfo)

mkdir /root/results/data
chmod 0777 /root/results
chmod 0777 /root/results/data

cd /root/results/data

echo "Process PCAPs using ${NUM_CORES} cores"

env --chdir /var/lib/postgresql setpriv --init-groups --reuid postgres -- createuser -s root || true

parallel -j $NUM_CORES "dropdb --if-exists root{ % }; createdb root{ % }; export PGDATABASE=root{ % }; ~/experiment-script/dbscripts/import.sh {}; ~/experiment-script/dbscripts/analysis.sh {}" ::: ../latencies-pre.pcap*.zst

#cp ~/plotter/* ~/results
#cd ~/results
#mkdir ~/results/figures
#python3 plotcreator.py figures ./results ./results
#make -i

# create irq plots
cd /root/experiment-script/irq
python3 irqprocessor.py /root/results /root/results/data
#./compile.py ~/irqplotter/results
#make -i
#pos_upload --force -r ~/irqplotter/
#pos_upload --force -r ~/irqplotter/figures/

cp -r /root/experiment-script/plotter/* /root/results
cd /root/results
mkdir /root/results/figures
python3 plotcreator.py figures data .
make -i

pos_upload -r /root/results/figures/
pos_upload -r /root/results/data/
#pos_upload Makefile
#pos_upload Makefile.conf.mk
#pos_upload compile.py
#pos_upload tumcolor.sty
#pos_upload hdrplot.py
#pos_upload hdrplot-text-create.py


