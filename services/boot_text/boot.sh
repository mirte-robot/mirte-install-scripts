#!/bin/bash

# needs mirte_screen_arm64 to be downloaded from https://github.com/arendjan/mirte-screen

# script to write last 5 lines of dmesg to test.txt
set -xe
/home/mirte/mirte_screen_arm64 -t 1 -f /home/mirte/test.txt &
PID=$!
while true; do
    sudo dmesg | tail -n 5 > /home/mirte/test.txt   
    sleep 1
done

kill $PID

# TODO: stop when mirte-ros is started
# TODO: what to write
# TODO: change pico code to not clean when watchdog was triggered last run.