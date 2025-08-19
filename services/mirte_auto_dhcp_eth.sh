#!/usr/bin/env bash

# nm dispatcher is whack and not running reliably or without the interface name.

# this script repeatedly checks eth0, when it goes up, wait for a few seconds
#           if no ip assigned: start dnsmasq
#           if ip assigned:don't do anything
# when eth0 goes down, kill dnsmasq if started

set -xe

# start dnsmasq
SUBNET=45
interface=eth0

dnsmasq_pid=$(pgrep -f "dnsmasq --address=/#/192.168.$SUBNET.1") || true

function cleanup {
	has_dhcp=false
	echo "Cleaning up..."
	if [ -n "$dnsmasq_pid" ]; then
		echo "Stopping dnsmasq with PID $dnsmasq_pid"
		sudo kill "$dnsmasq_pid" || true
		dnsmasq_pid=""
	else
		echo "No dnsmasq process found."
	fi
	sudo ip address del 192.168."$SUBNET".1/24 dev eth0 || true
	#   exit 0
	echo "Cleanup complete."
	#   exit 0
}

function start_dhcp {
	cleanup
	has_dhcp=true
	sudo ip address add 192.168."$SUBNET".1/24 dev eth0
	sudo dnsmasq --address=/#/192.168."$SUBNET".1 --dhcp-range=192.168."$SUBNET".10,192.168."$SUBNET".100 --conf-file --domain-needed --bogus-priv --server=8.8.8.8 --dhcp-option=option:dns-server,8.8.8.8 --interface="$interface" --except-interface=lo --bind-interfaces -p0 --dhcp-leasefile=/tmp/dnsmasq.leases
	dnsmasq_pid=$(pgrep -f "dnsmasq --address=/#/192.168.$SUBNET.1")
}

function check_up {
	is_up=$(ip addr show $interface | grep -q "state UP" && echo true || echo false)
	has_ip=$(ip addr show $interface | grep -q "inet " && echo true || echo false)
	if [ "$is_up" = false ]; then
		SECONDS=0
	elif [ $SECONDS -gt 10 ] && [ "$has_ip" = false ]; then
		echo "Interface $interface has been up for more than 10 seconds."
		echo "No IP address assigned, starting DHCP server."
		start_dhcp
	fi
}

function check_down {
	is_up=$(ip addr show $interface | grep -q "state UP" && echo true || echo false)
	if [ "$is_up" = false ] && [ "$has_dhcp" = true ]; then
		echo "Interface $interface is down, stopping DHCP server."
		cleanup
	fi
}

trap cleanup EXIT

is_up=false
has_dhcp=false
while true; do
	check_up
	check_down
	sleep 5
done
