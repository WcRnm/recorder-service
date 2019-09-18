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

# LED control colors
ON=red
OFF=green
DISABLED=off

FNAME=""
escape_char=$(printf "\u1b")

#--------------------------------------------------------


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

    chmod a+rw "${REC_DIR}/$FNAME.mp3"
    FNAME=""
  fi

  $LED $OFF
}

function upload_tasks()
{
  # Move the mp3 file to the upload directory.
  mv -f "${REC_DIR}"/*.mp3 "${UP_DIR}"

  # Delete old recordings if there too many in the upload dir 
  pushd "${UP_DIR}" >/dev/null
    N=$((UP_MAX_FILES+1))
    ls -tp | grep -v '/$' | tail -n +$N | xargs -I {} rm -- {}
  popd >/dev/null
}

function message()
{
  $LOG "+----------------------------------------+"
  if [ "$1" = "start" ]; then
    $LOG "|     PRESS A KEY TO START RECORDING     |"
  else
    $LOG "|     PRESS A KEY TO STOP RECORDING      |"
  fi
  $LOG "+----------------------------------------+"
}
#--------------------------------------------------------

# Log some current settings
$LOG "VERSION=$VERSION"
$LOG "REC_DIR=$REC_DIR"
$LOG "UP_DIR=$UP_DIR"

# Create directories if they don't exist
mkdir -p $REC_DIR/upload
mkdir -p $UP_DIR

# Do the upload tasks. This is in case we had lost power during the last record session
upload_tasks

message start

while read -rsn1 keypress; do
  if [[ $keypress == $escape_char ]]; then
    read -rsn2 keypress # read 2 more chars
  fi

  if [[ $recording = 0 ]]; then
    recording=1
    start_recording
    sleep 0.5
    message stop
  else
    recording=0
    stop_recording
    upload_tasks
    message start
  fi
done

$LOG "recorder done"
$LED $DISABLED
