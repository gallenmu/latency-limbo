#!/bin/bash

set -e
set -x

pos_sync
echo "starting experiment: $(date)"

MEASUREMENT_TIME=$(pos_get_variable -g measurement_time)
IRQRECORDING=$(pos_get_variable -l irqrecording)
DISABLENIC=$(pos_get_variable -l disablenic)
ENIC=$(pos_get_variable enic-vmhost)

if [ ! $IRQRECORDING -eq 0 ]; then
        sleep 2
        echo "start irq recording"
        pos_run -l irqlvmhost -- taskset -c 0 /root/experiment-script/irq/irqrecorder.py
        sleep 2
else
        echo "no irq recording"
fi

# avoid disturbance by disabling eno1 during the latency measurement            
if [ ! $DISABLENIC -eq 0 ]; then                                                
        echo "disable nic"                                                      
        ip link set dev "$ENIC" down                                               
        sleep $(($MEASUREMENT_TIME+120))                                        
        ip link set dev "$ENIC" up                                                 
        sleep 15                                                                
else                                                                            
        sleep $(($MEASUREMENT_TIME+120))                                        
fi         


pos_sync

if [ ! $IRQRECORDING -eq 0 ]; then
        pos_kill -l irqvmhost
        sleep 2
        pos_upload -l irqrecorder-vmhost.csv
fi

echo 'all done'
