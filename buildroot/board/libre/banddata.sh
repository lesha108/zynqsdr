#!/bin/bash

outport="/dev/ttyUL0"
# infinite loop to send RX and TX LO freqs
while true
do
#    echo "Loop again..."
    rxlo=$(cat /sys/bus/iio/devices/iio:device0/out_altvoltage0_RX_LO_frequency)
    txlo=$(cat /sys/bus/iio/devices/iio:device0/out_altvoltage1_TX_LO_frequency)
    echo -n "T" > $outport
    echo -n $txlo > $outport
    echo -n "R" > $outport
    echo $rxlo > $outport
    sleep 1
done

