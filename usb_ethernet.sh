#!/bin/bash

#TODO: find musb
# This script creates USB gadgets usign ConfigFS for both Linux/MacOS and Windows
# The Linux and MacOS version will connect to usb0, whil Windows will connect
# to usb1. Both networks then are shown on the host.
MIRTE_SRC_DIR=/usr/local/src/mirte

sudo killall -9 dnsmasq
sudo $MIRTE_SRC_DIR/mirte-install-scripts/ev3-usb.sh down "$(ls /sys/class/udc | tail -n1)"
sudo $MIRTE_SRC_DIR/mirte-install-scripts/ev3-usb.sh up "$(ls /sys/class/udc | tail -n1)"

# For now, we just create a different IP address for each interface. We need
# to change this to private namespaces (see below). In order to getinthernet
# in teh namepsaces as well (and teh running servers?) see:
# https://gist.github.com/dpino/6c0dca1742093346461e11aa8f608a99

#sudo ip address add 192.168.42.3/24 dev usb0
#sudo ifconfig usb0 up
sudo ip address add 192.168.43.1/24 dev usb1
sudo ifconfig usb1 up

#TODO: make persitent
# Forward the traffic
#echo 'nameserver 8.8.8.8' >> /etc/resolv.conf
sudo sysctl -w net.ipv4.ip_forward=1
#sudo iptables -A FORWARD --in-interface usb1 -j ACCEPT
#sudo iptables --table nat -A POSTROUTING --out-interface wlan0 -j MASQUERADE

sudo iptables -F
sudo iptables -t nat -A POSTROUTING -o wlan0 -j MASQUERADE
sudo iptables -A FORWARD -i wlan0 -o usb1 -m state --state RELATED,ESTABLISHED -j ACCEPT
sudo iptables -A FORWARD -i usb1 -o wlan0 -j ACCEPT

#and forward all traffic to locahost
sudo iptables -t nat -A POSTROUTING -i usb1 -d 192.168.43.1 -j DNAT --to-destination 127.0.0.1

# For now we have to start the dhcp server before wificonnect. Not needed
# after we moved to different namespaces
# For some reason we neet to set the dns-server manually
sudo dnsmasq --address=/#/192.168.43.1 --dhcp-range=192.168.43.10,192.168.43.100 --conf-file --domain-needed --bogus-priv --server=8.8.8.8 --dhcp-option=option:dns-server,8.8.8.8 --interface=usb1 --except-interface=lo --bind-interfaces

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
