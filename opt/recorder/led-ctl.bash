#!/bin/bash

LED=/dev/ttyACM0

userid=`id -u`
if [[ 0 != $userid ]]; then
   echo "Not root, bye."
   exit
fi

if [ ! -e $LED ]; then
   echo "NO light installed: $LED not found."
   exit 1
fi
stty -F $LED 9600 raw -echo -echoe -echok -echoctl -echoke

if [[ x$1 = x ]]; then
   echo "Turning off."
   echo "#000000" > $LED
   exit 0
fi

help()
{
      echo "Control the USB LED"
      echo "  led-ctl.bash [color|state]"
      echo "    Colors: red, green, blue, yellow, white"
      echo 
      echo "    States:"
      echo "      off (default)"
      echo "         aliases: poweroff, shutdown, halt, reboot, stop"
      echo "      on (red)"
      echo "         aliases: record"
}

case $1 in
   off|poweroff|shutdown|halt|reboot|stop)
      echo "#000000" > $LED
      ;;
   red|record|on)
      echo "#ff0000" > $LED
      ;;
   green)
      echo "#008000" > $LED
      ;;
   blue)
      echo "#0000ff" > $LED
      ;;
   white)
      echo "#ffffff" > $LED
      ;;
   yellow)
      echo "#ffff00" > $LED
      ;;
   *)
      help
      ;;
esac

