#!/bin/bash

#TODO: find musb
# This script creates USB gadgets usign ConfigFS for both Linux/MacOS and Windows
# The Linux and MacOS version will connect to usb0, whil Windows will connect
# to usb1. Both networks then are shown on the host.
MIRTE_SRC_DIR=/usr/local/src/mirte

# on orange pi zero1 the g_serial module is set by default, disable it and load the g_ether module
# keeping /etc/modules with g_serial makes it possible to still have a serial connection when mirte-ap is disabled by the user.
modprobe -r g_serial || true
modprobe g_ether || true

sudo killall -9 dnsmasq
sudo $MIRTE_SRC_DIR/mirte-install-scripts/ev3-usb.sh down "$(ls /sys/class/udc | tail -n1)" || true
sudo $MIRTE_SRC_DIR/mirte-install-scripts/ev3-usb.sh up "$(ls /sys/class/udc | tail -n1)" || true

function setup_network_usb() {
	USB_NAME=$1
	SUBNET=$2
	echo "setup $USB_NAME on 192.168.$SUBNET.xxx"
	sudo ip address add 192.168."$SUBNET".1/24 dev "$USB_NAME"
	sudo ip link set up "$USB_NAME"

	#TODO: make persitent
	# Forward the traffic
	#echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
	sudo sysctl -w net.ipv4.ip_forward=1
	#sudo iptables -A FORWARD --in-interface usb1 -j ACCEPT
	#sudo iptables --table nat -A POSTROUTING --out-interface wlan0 -j MASQUERADE

	sudo iptables -F
	sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
	sudo iptables -A FORWARD -i wlan0 -o "$USB_NAME" -m state --state RELATED,ESTABLISHED -j ACCEPT
	sudo iptables -A FORWARD -i "$USB_NAME" -o wlan0 -j ACCEPT

	#and forward all traffic to locahost
	# AJ: this command does nothing, only gives "iptables v1.8.4 (legacy): Can't use -i with POSTROUTING"
	# sudo iptables -t nat -A POSTROUTING -i "$USB_NAME" -d 192.168."$SUBNET".1 -j DNAT --to-destination 127.0.0.1

	# For now we have to start the dhcp server before wificonnect. Not needed
	# after we moved to different namespaces
	# For some reason we neet to set the dns-server manually
	sudo dnsmasq --address=/#/192.168."$SUBNET".1 --dhcp-range=192.168."$SUBNET".10,192.168."$SUBNET".100 --conf-file --domain-needed --bogus-priv --server=8.8.8.8 --dhcp-option=option:dns-server,8.8.8.8 --interface="$USB_NAME" --except-interface=lo --bind-interfaces
}

if [ -d /sys/class/net/usb1 ]; then
	setup_network_usb usb1 43
fi
if [ -d /sys/class/net/usb0 ]; then
	setup_network_usb usb0 44
fi

# For now, we just create a different IP address for each interface. We need
# to change this to private namespaces (see below). In order to getinthernet
# in teh namepsaces as well (and teh running servers?) see:
# https://gist.github.com/dpino/6c0dca1742093346461e11aa8f608a99

# Since we want both networks to have the same IP address as the wifi AP (192.168.42.1)
# we need to have a seperate network namespace for both of them.

# create network namespace for unix (usb0)
#sudo ip netns add unix
#sudo ip link set dev usb0 netns unix
#sudo ip netns exec unix ip addr add 127.0.0.1/8 dev lo
#sudo ip netns exec unix ip address add 192.168.42.1/24 dev usb0
#sudo ip netns exec unix ifconfig usb0 up
#sudo ip netns exec unix dnsmasq --address=/#/192.168.42.1 --dhcp-range=192.168.42.10,192.168.42.100 --conf-file

# create network namespace for linux (usb1)
#sudo ip netns add windows
#sudo ip link set dev usb1 netns windows
#sudo ip netns exec windows ip addr add 127.0.0.1/8 dev lo
#sudo ip netns exec windows ip address add 192.168.42.1/24 dev usb1
#sudo ip netns exec windows ifconfig usb1 up
#sudo ip netns exec windows dnsmasq --address=/#/192.168.42.1 --dhcp-range=192.168.42.10,192.168.42.100 --conf-file
