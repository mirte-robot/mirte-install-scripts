#!/bin/bash

# set -xe
wifi="wlan0"

# wait for wlan0 to be available
while ! ip addr show "$wifi" &>/dev/null; do
	echo "Waiting for $wifi to be available..."
	sleep 2
done

mac=$(ip addr show "$wifi" | awk '/ether/{print $2}')
echo $mac
# if mac in the list, then use the domain id
macs=(
	"1	e0:51:d8:67:b1:84"
	"2	e0:51:d8:67:af:f2"
	"3	e0:51:d8:67:b2:32"
	"4	e0:51:d8:67:af:a6"
	"5	e0:51:d8:67:66:be"
	"6	e0:51:d8:67:ae:9e"
	"7	e0:51:d8:67:76:ac"
	"8	e0:51:d8:67:c1:8e"
	"9	e0:51:d8:67:b1:8e"
	"10	e0:51:d8:67:b0:7e"
	"11	e0:51:d8:67:b1:da"
	"12	e0:51:d8:67:b2:66"
	"13	e0:51:d8:67:b2:40"
	"14	e0:51:d8:67:c1:38"
	"15	e0:51:d8:67:67:04"
	"16	e0:51:d8:67:67:50"
	"17	e0:51:d8:67:67:26"
	"18	e0:51:d8:67:c1:a0"
	"19	e0:51:d8:67:c1:36"
	"20	e0:51:d8:67:67:3a"
	"21	e0:51:d8:67:67:20"
	"22	e0:51:d8:67:b1:a8"
	"23	e0:51:d8:67:c1:26"
	"24	e0:51:d8:67:c1:32"
	"25	e0:51:d8:67:66:68"
	"26	e0:51:d8:67:ae:96"
	"27	e0:51:d8:67:b0:16"
	"28	04:56:e5:61:9d:51"
)
for i in "${macs[@]}"; do
	set -- $i # Convert the "tuple" into the param args $1 $2...
	if [[ "$2" == "$mac" ]]; then
		echo "Found matching MAC address: $mac, setting ROS_DOMAIN_ID to $1"
		echo -e "\nexport ROS_DOMAIN_ID=$1\n" >>~/.bashrc || true
		echo -e "\nexport ROS_DOMAIN_ID=$1\n" >>~/.mirte_settings.sh || true
		ROS_DOMAIN_ID="$1"
		break
	fi
done

echo "ROS_DOMAIN_ID is set to $ROS_DOMAIN_ID"
