#!/bin/bash
source /home/mirte/mirte_ws/devel/setup.bash

ip=$(hostname -I | awk '{print $1}') #just get the first ip addr
if [ "$(echo $ip | wc -w)" -ne 1 ]; then
	# happens at boot, when the network is not yet up
	echo "multiple or none, wont use the ip from hostname:"
	hostname -I
else
	export ROS_IP="$ip"
	export ROS_MASTER_URI="http://$ip:11311/"
	echo "ROS_IP=$ROS_IP"
	echo "ROS_MASTER_URI=$ROS_MASTER_URI"
fi
# If the robot user wants to add their own config:
# source /home/mirte/.bashrc
roslaunch mirte_bringup minimal_master.launch
