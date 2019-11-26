#!/bin/bash

# source and destination directories
SRC=$1
DST=$2

LOG="logger -s -t upload"

function die()
{
  $LOG "$1"
  exit
}

[ -d "$SRC" ] || die "SRC does not exist: $SRC"
[ -d "$DST" ] || die "DST does not exist: $DST"

FILES="$SRC/*.mp3"
for f in $FILES
do
  $LOG "$f"

  # TODO: This will only work if the destination is a directory.
  #       Consider adding support for other upload methods.
  $LOG "rsync -a --remove-source-files $f $DST"
  rsync -a --remove-source-files "$f" "$DST"
done
