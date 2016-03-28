#!/bin/bash

if [ -z "$1" ]; then
  echo "This will play a cd on my ancient MacBook Pro running Debian 8"
  echo "Run it like this to play tracks 5 to 7 at regular speed (1)"
  echo "  $0 5 7 1"
  echo ""
  echo "Run it like this to play tracks 5 to 7 25% faster than usual (1.25)"
  echo "  $0 5 7 1.25"
  exit
else
  START_TRACK_NBR=$1
fi

if [ -z "$2" ]; then
  END_TRACK_NBR=$START_TRACK_NBR
else
  END_TRACK_NBR=$2
fi

if [ -z "$3" ]; then
  SPEED=1
else
  SPEED=$3
fi

mplayer  -speed "${SPEED}"  -cdrom-device /dev/sr0 cdda://${START_TRACK_NBR}-${END_TRACK_NBR}:${SPEED}

