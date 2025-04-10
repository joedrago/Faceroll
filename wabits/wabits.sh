#!/bin/bash

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

ffmpeg ${PIPELINE} -f yuv4mpegpipe -r 10 - | /Users/joe/work/faceroll/wabits/build/wabits

