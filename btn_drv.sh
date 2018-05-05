#!/bin/sh


inPinNum=24

inPin=/sys/class/gpio/gpio$inPinNum

echo $inPinNum > /sys/class/gpio/export

sleep 1

echo in > $inPin/direction


pinState=`cat /sys/class/gpio/gpio$inPinNum/value`
lastPinState=$pinState

touch btnTimer

while true; do

    pinState=`cat /sys/class/gpio/gpio$inPinNum/value`

    if [ $pinState -eq 0 ]; then
        touch btnTimer
    fi

    touch -d '-5 second' limit
    if [ limit -nt btnTimer ]; then
        touch btnTimer
        shutdown now
    fi

    sleep 0.1;
done
