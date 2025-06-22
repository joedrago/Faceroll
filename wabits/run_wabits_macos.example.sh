#!/bin/bash

# Run this with no arguments to list possible macos record destinations. Find
# out which number corresponds to the monitor you play on. Run with that number
# as the first argument to begin capture and Lua processing. Adjust the crop
# rectangle (X:Y:W:H) to correspond to the mod's rectangle. Pass the name of a
# PNG on the commandline as the second argument to output the rectangle's
# capture once for positioning debugging.

SCRIPT_DIR=$( cd -- "$( dirname -- $(realpath "${BASH_SOURCE[0]}") )" &> /dev/null && pwd )

PIPELINE="-y -f avfoundation -i $1 -vf crop=30:60:2221:9"

if [ -z "$1" ]; then
    ffmpeg -f avfoundation -list_devices true -i ""
    exit
fi

if [ ! -z "$2" ]; then
    echo "Creating test capture PNG: $2"
    ffmpeg ${PIPELINE} -vframes 1 "$2"
    exit
fi

ffmpeg ${PIPELINE} -f yuv4mpegpipe -r 10 - | ${SCRIPT_DIR}/build/wabits
