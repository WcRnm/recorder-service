#! /bin/bash

LOG="logger -t onboot[$BASHPID]"

$LOG "This is a sound recorder appliance. Hit a key to start/stop recording."

/opt/recorder/rec-ctl.bash
