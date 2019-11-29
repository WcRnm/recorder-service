#!/bin/bash
VERSION="0.6"
DEBUG=0

# ACTIVE BUTTONS
#  Note: prefer to us keys that are not effected by the NumLock key.
BTN_RECORD_START="+"
BTN_RECORD_STOP="-"
BTN_PROJECTOR="*"

# Script to start/stop audio recording using a keypad
#
#  1) Active recording is in REC_DIR
#  2) Recordings ready for upload are in UP_DIR

LOG="logger -s -t rec-ctl[$BASHPID]"

recording=0
projecting=0

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

function DBG()
{
  if [[ "$DEBUG" = "1" ]]; then
    $LOG "DBG: $1"
  fi
}

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
  # Move mp3 files to the upload directory.
  mv -f "${REC_DIR}"/*.mp3 "${UP_PENDING}" 2>/dev/null

  $LOG "Uploading $UP_PENDING $UP_DEST"
  $UPLOAD "$UP_PENDING" "$UP_DEST"

  # Delete old recordings if there too many in the upload dir 
  $LOG "Removing old files from $UP_PENDING"
  pushd "${UP_PENDING}" >/dev/null || exit
    N=$((UP_MAX_FILES+1))
    ls -tp | grep -v '/$' | tail -n +$N | xargs -I {} rm -- {}
  popd >/dev/null || exit
}

function message()
{
  $LOG "+----------------------------------------+"
  if [ "$1" = "start" ]; then
    $LOG "|     PRESS '${BTN_RECORD_START}' TO START RECORDING."
  elif [ "$1" = "stop" ]; then
    $LOG "|     PRESS '${BTN_RECORD_STOP}' TO STOP RECORDING."
  elif [ "$1" = "timeout" ]; then
    $LOG "|     TIMEOUT. MAX DURATION: $REC_MAX_DURATION sec."
  elif [ "$1" = "proj_on" ]; then
    $LOG "|     PRESS '${BTN_PROJECTOR}' TO TURN ON PROJECTOR. (TBD)"
  elif [ "$1" = "proj_off" ]; then
    $LOG "|     PRESS '${BTN_PROJECTOR}' TO TURN OFF PROJECTOR. (TBD)"
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

message "proj_on"
message "start"

$LED $OFF

while true; do
  DBG "read..."
  read -rsn1 -t "$REC_MAX_DURATION" keypress
  
  if [ "$?" != 0 ]; then
    DBG "timeout..."
    # timeout
    if [ $recording = 0 ]; then
      # timeout, but not recording, keep waiting...
      upload_tasks
      continue
    else
      message "timeout"
    fi
  else
    if [[ "$keypress" == "$escape_char" ]]; then
      DBG "escape"
      # read 2 more chars, this is arrow key (on a keypad)
      read -rsn2 keypress || continue
    fi
  fi

  DBG "key: '$keypress'"

  if [[ "$BTN_RECORD_START" = "$keypress" ]]; then
    DBG "record on button"
    if [[ $recording = 0 ]]; then
      DBG "RECORD ON"
      recording=1
      start_recording
      sleep 0.5
      message "stop"
    fi
  elif [[ "$BTN_RECORD_STOP" = "$keypress" ]]; then
    DBG "record off button"
    if [[ $recording = 1 ]]; then
      DBG "RECORD OFF"
      recording=0
      stop_recording
      upload_tasks
      message "start"
    fi
  elif [[ "$BTN_PROJECTOR" = "$keypress" ]]; then
    DBG "projector button"
    if [[ $projecting = 0 ]]; then
      DBG "PROJECTOR ON (TBD)"
      projecting=1
    else
      DBG "PROJECTOR OFF (TBD)"
      projecting=0
    fi
  fi
done

$LOG "recorder done"
$LED $DISABLED
