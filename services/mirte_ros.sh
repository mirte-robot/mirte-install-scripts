#!/bin/bash

# read ./mirte_ros_type.sh to set MIRTE_TYPE, which is used to determine which launch file to use
source $PWD/mirte_ros_type.sh

# If the robot user wants to add their own config:
source /home/mirte/.mirte_settings.sh
mkdir -p $ROS_LOG_DIR

if [[ $MIRTE_TYPE == "mirte-master" || $MIRTE_TYPE == "mirte_master" ]]; then
	LAUNCH_FILE=minimal_master
else
	LAUNCH_FILE=minimal
fi

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
