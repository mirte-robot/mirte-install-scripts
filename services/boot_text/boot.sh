#!/bin/bash
set -xe

# needs mirte_screen_arm64 to be downloaded from https://github.com/arendjan/mirte-screen


get_text() {
    echo "Booting Mirte..." > /home/mirte/test.txt
    uptime_sec=$(awk '{print int($1)}' /proc/uptime)
    echo "Uptime: $uptime_sec seconds" >> /home/mirte/test.txt
    # if wifi on, show ip address, otherwise show "No wifi"
    if iwconfig 2>&1 | grep -q "ESSID:off/any"; then
        echo "No wifi" >> /home/mirte/test.txt
    else
        ip_address=$(hostname -I | awk '{print $1}')
        echo "IP address: $ip_address" >> /home/mirte/test.txt
    fi
}


/home/mirte/mirte_screen_arm64 -t 1 -f /home/mirte/test.txt &
PID=$!
while true; do
    get_text
    sleep 1
done

kill $PID

# TODO: stop when mirte-ros is started
# TODO: what to write
# TODO: change pico code to not clean when watchdog was triggered last run.