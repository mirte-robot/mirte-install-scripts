#!/bin/bash
source /home/mirte/mirte_ws/devel/setup.bash

ip=$(hostname -I | awk '{print $1}' ) #just get the first ip addr
echo $ip
if [ "$(echo $ip | wc -w)" -ne 1 ]; then
echo "multiple, wont use the ip from hostname"
echo $ip
echo hostname -I
else 
export ROS_IP="$ip"
export ROS_MASTER_URI="http://$ip:11311/"
echo $ROS_IP
echo $ROS_MASTER_URI
fi
# If the robot user wants to add their own config:
# source /home/mirte/.bashrc
roslaunch mirte_bringup minimal_master.launch