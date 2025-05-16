#!/bin/bash

# by default use minimal launch file, but allow to override to minimal_master
LAUNCH_FILE="${1:-minimal}"

# If the robot user wants to add their own config:
source /home/mirte/.mirte_settings.sh
mkdir -p $ROS_LOG_DIR

source /home/mirte/mirte_ws/install/setup.bash
# if zenoh is enabled, start the zenoh daemon
if [ "$RMW_IMPLEMENTATION" = "rmw_zenoh_cpp" ]; then
	# kill ros deamon
	sudo pkill -9 -f ^ros && ros2 daemon stop
	ros2 run rmw_zenoh_cpp rmw_zenohd &
fi
if [ "$MIRTE_FASTDDS" = "true" ]; then
	if [ -z "$(ss -l | grep -w "11811")" ]; then
		echo "starting discovery server on port 11811"
		# echo "Please run a discovery server on port 11811 with the following command:"
		fastdds discovery --server-id 0 -p 11811 &
	fi
	ros2 daemon stop
	ros2 daemon start
fi
ros2 launch mirte_bringup $LAUNCH_FILE.launch.py
