#!/bin/sh


inPinNum=17
outPinNum=18


inPin=/sys/class/gpio/gpio$inPinNum
outPin=/sys/class/gpio/gpio$outPinNum

echo $inPinNum > /sys/class/gpio/export
echo $outPinNum > /sys/class/gpio/export

sleep 1

echo in > $inPin/direction
echo out > $outPin/direction


#initial, online, preSleep, sleep
state="initial"
lastState="initial"


onStateChange()
{
    state=$1
    lastState=$2

    #echo "onStateChange" $lastState " " $state

    case "$state" in

        "online")
            onWakeup
        ;;


        "sleep")
            onSleep
        ;;
    esac
}


onSleep()
{
    /etc/init.d/networking stop
    echo 0x0 > /sys/devices/platform/soc/3f980000.usb/buspower

    cpufreq-set -g powersave
}

onWakeup()
{
    cpufreq-set -g performance

    echo 0x1 > /sys/devices/platform/soc/3f980000.usb/buspower
    /etc/init.d/networking start
}

indiacte()
{
    case "$state" in

        "online")
            echo 1 > /sys/class/gpio/gpio$outPinNum/value
        ;;

        "preSleep")

            touch -d '-0.5 second' ledLimit
            if [ ledLimit -nt ledTimer ]; then
            touch ledTimer

                ledState=`cat /sys/class/gpio/gpio$outPinNum/value`
                if [ $ledState -eq 0 ]; then
                    echo 1 > /sys/class/gpio/gpio$outPinNum/value
                    ledState=1
                else
                    echo 0 > /sys/class/gpio/gpio$outPinNum/value
                    ledState=0
                fi
            fi
        ;;

        "sleep")
            touch -d '-1 second' ledLimit
            if [ ledLimit -nt ledTimer ]; then
            touch ledTimer
                echo 1 > /sys/class/gpio/gpio$outPinNum/value
                sleep 0.1
                echo 0 > /sys/class/gpio/gpio$outPinNum/value
           fi
        ;;
    esac
}


pinState=`cat /sys/class/gpio/gpio$inPinNum/value`
lastPinState=$pinState

if [ $pinState -eq 1 ]; then
    state="online"
    lastState="online"
else
    state="preSleep"
    lastState="preSleep"
fi

touch sleepTimer
touch ledTimer

while true; do

    pinState=`cat /sys/class/gpio/gpio$inPinNum/value`

    if [ $pinState -eq 1 ]; then
        touch sleepTimer
    fi


    if [ $pinState -ne $lastPinState ]; then

        case "$state" in

            "online")
                if [ $pinState -eq 0 ]; then
                    state="preSleep"
                fi
            ;;

            "preSleep")
                if [ $pinState -eq 1 ]; then
                    state="online"
                fi
            ;;

            "sleep")
                touch sleepTimer

                if [ $pinState -eq 1 ]; then
                    state="online"
                fi
            ;;

            *)
            echo "Wrong State"
        esac
    fi


    touch -d '-1 minute' limit
    if [ limit -nt sleepTimer ]; then
        touch sleepTimer
        state="sleep"
    fi


    if [ $state != $lastState ]; then
        onStateChange $state $lastState
        lastState=$state
    fi

    indiacte

    lastPinState=$pinState
    sleep 0.1;
done
