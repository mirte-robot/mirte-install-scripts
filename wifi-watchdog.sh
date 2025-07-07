#!/bin/sh

dmesg --follow | while read -r line; do
        # OrangePi Zero 1: xradio WSM-ERR: CMD timeout!
        # OrangePi Zero 2: WCN_ERR: dumpmem_rx_callback open
	if echo "$line" | grep -qE "xradio WSM-ERR: CMD timeout!|WCN_ERR: dumpmem_rx_callback open"; then
		echo "CRASH! REBOOT!" >/dev/kmsg
		echo "$line" >> /home/mirte/wifi-watchdog.err
		echo b >/proc/sysrq-trigger
	fi
done
