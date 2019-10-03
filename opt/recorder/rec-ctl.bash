#!/bin/bash
VERSION="0.4"

# Script to start/stop audio recording using a keypad
#
#  1) Active recording is in REC_DIR
#  2) Recordings ready for upload are in UP_DIR

LOG="logger -s -t rec-ctl[$BASHPID]"

$LOG "This is a sound recorder appliance. Hit a key to start/stop recording."

recording=0

RECHOME=/opt/recorder
LED=$RECHOME/led-ctl.bash
UPLOAD=$RECHOME/upload.bash

source $RECHOME/rec-settings.conf

# LED control colors
ON=red
OFF=green
DISABLED=off

FNAME=""
escape_char=$(printf "\u1b")

#--------------------------------------------------------

function die()
{
  $LOG "FATAL line:$1 $2"
  exit
}

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

  arecord -D "$MIC_DEV" -f cd -c 2 -t raw | lame -r -b "$MP4_BITRATE" - "$REC_DIR/$FNAME.mp3" &
}

function stop_recording()
{
  if [[ "$FNAME" != "" ]]; then
    $LOG "stop:  '$FNAME'"
    killall arecord

    FAIL=0
    for job in $(jobs -p)
    do
        $LOG "wait for job:$job"
        wait "$job" || (( FAIL+=1 ))
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
  mv -f "${REC_DIR}"/*.mp3 "${UP_PENDING}"

  $UPLOAD "$UP_PENDING" "$UP_DEST"

  # Delete old recordings if there too many in the upload dir 
  pushd "${UP_PENDING}" >/dev/null || exit
    N=$((UP_MAX_FILES+1))
    ls -tp | grep -v '/$' | tail -n +$N | xargs -I {} rm -- {}
  popd >/dev/null || exit
}

function message()
{
  $LOG "+----------------------------------------+"
  if [ "$1" = "start" ]; then
    $LOG "|     PRESS A KEY TO START RECORDING."
  elif [ "$1" = "stop" ]; then
    $LOG "|     PRESS A KEY TO STOP RECORDING."
  elif [ "$1" = "timeout" ]; then
    $LOG "|     TIMEOUT. MAX DURATION: $REC_MAX_DURATION sec."
  fi
  $LOG "+----------------------------------------+"
}
#--------------------------------------------------------

# Log some current settings
$LOG "VERSION           = $VERSION"
$LOG "REC_DIR           = $REC_DIR"
$LOG "UP_PENDING        = $UP_PENDING"
$LOG "UP_DEST           = $UP_DEST"
$LOG "REC_MAX_DURATION  = $REC_MAX_DURATION"

# Create directories if they don't exist
mkdir -p "$REC_DIR"/upload
mkdir -p "$UP_PENDING"

# Do the upload tasks. This is in case we had lost power during the last record session
upload_tasks

message start

$LED $OFF

while true; do
  read -rsn1 -t "$REC_MAX_DURATION" keypress
  
  if [ "$?" != 0 ]; then
    # timeout
    if [ $recording = 0 ]; then
      # timeout, but not recording, keep waiting...
      upload_tasks
      continue
    else
      message timeout
    fi
  else
    if [[ "$keypress" == "$escape_char" ]]; then
      # read 2 more chars, this is arrow key (on a keypad)
      read -rsn2 keypress || continue
    fi
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
