#!/bin/bash

DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" >/dev/null 2>&1 && pwd )"

sudo cp -f "$DIR/opt/recorder/rec-ctl.bash"      "/opt/recorder/"
sudo cp -f "$DIR/opt/recorder/led-ctl.bash"      "/opt/recorder/"
sudo cp -f "$DIR/opt/recorder/upload.bash"       "/opt/recorder/"
sudo cp -f "$DIR/opt/recorder/rec-settings.conf" "/opt/recorder/"

sudo cp -f "$DIR/root/onboot.bash"               "/root/"