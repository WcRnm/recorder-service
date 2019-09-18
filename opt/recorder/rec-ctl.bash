#!/bin/bash

# Script to start/stop audio recording using a keypad
#
#  1) Active recording is in REC_DIR
#  2) Recordings ready for upload are in UP_DIR

LOG="logger -s -t rec-ctl[$BASHPID]"

$LOG "This is a sound recorder appliance. Hit a key to start/stop recording."

recording=0
device=plughw:1,0

RECHOME=/opt/recorder
LED=$RECHOME/led-ctl.bash

source $RECHOME/rec-settings.conf

ON=red
OFF=green
DISABLED=off

escape_char=$(printf "\u1b")

FNAME=""

mkdir -p $REC_DIR/upload

$LOG "REC_DIR=$REC_DIR"

function cleanup()
{
  $LOG "cleanup"
  stop_recording
  $LED $DISABLED
  exit
}

trap cleanup SIGINT

function start_recording()
{
  timestamp=$(date "+%Y%m%d-%H%M%S")
  FNAME="$FILE_PREFIX-$timestamp"
  $LOG "start: '$FNAME'"
  $LED $ON

  arecord -D $MIC_DEV -f cd -c 2 -t raw | lame -r -b $MP4_BITRATE - "$REC_DIR/$FNAME.mp3" &
}

function stop_recording()
{
  if [[ "$FNAME" != "" ]]; then
    $LOG "stop:  '$FNAME'"
    killall arecord

    FAIL=0
    for job in `jobs -p`
    do
        $LOG "wait for job:$job"
        wait $job || let "FAIL+=1"
    done

    if [ "$FAIL" != "0" ]; then
      $LOG "wait fail ($FAIL)"
    fi

    chmod a+rw "$REC_DIR/$FNAME.mp3"
    FNAME=""
  fi

  mv "$REC_DIR/*.mp3" "$UP_DIR/upload/*.mp3"
  # TODO: if more than UP_MAX_FILES in upload, then delete the oldest file

  $LED $OFF
  $LOG "+----------------------------------------+"
  $LOG "|---- PRESS A KEY TO START RECORDING ----|"
  $LOG "+----------------------------------------+"
}

stop_recording

while read -rsn1 keypress; do
  if [[ $keypress == $escape_char ]]; then
    read -rsn2 keypress # read 2 more chars
  fi

  if [[ $recording = 0 ]]; then
    recording=1
    start_recording
  else
    recording=0
    stop_recording
  fi
done

$LOG "recorder done"
$LED $DISABLED
