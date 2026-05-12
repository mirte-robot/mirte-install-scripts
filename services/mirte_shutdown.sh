#!/bin/bash
# set -xe
# Don't shutdown if only stopping the service

if ! systemctl list-jobs | grep -q -E 'shutdown.target.*start'; then
	echo "shutdown target not active"
	exit
fi

REBOOT=false
# if rebooting, then dont shutdown the robot
if systemctl list-jobs | grep -q -E 'reboot.target.*start'; then
	echo "reboot target active"
	REBOOT=true
fi

source /home/mirte/.bashrc
source /home/mirte/.mirte_settings.sh
source /home/mirte/mirte_ws/install/setup.bash
touch /home/mirte/.shutdown
service=/io/oled/oled/set_text
shutdown_service=/io/power/power_watcher/shutdown
if [ "$MIRTE_USE_MULTIROBOT" = "true" ]; then
	mirte_space=$(cat /etc/hostname | tr '[:upper:]' '[:lower:]' | tr '-' '_')
	service="/$mirte_space$service"
	shutdown_service="/$mirte_space$shutdown_service"
fi

ros2 service list || true # make sure ros2 daemon is running
ros2 service list || true # make sure ros2 daemon is running

stop_service="/stop"
if [ "$(ros2 service list | grep "$stop_service$")" ]; then
	ros2 service call "$stop_service" std_srvs/srv/Empty "{}"
fi

if [ "$(ros2 service list | grep "$service$")" ] && [ "$REBOOT" = "false" ]; then
	ros2 service call "$service" mirte_msgs/srv/SetOLEDText "{ text: 'Shutting down...'}"
	ros2 service call "$shutdown_service" std_srvs/srv/SetBool "{ data: true }"
fi

if [ "$(ros2 service list | grep "$service$")" ] && [ "$REBOOT" = "true" ]; then
	ros2 service call "$service" mirte_msgs/srv/SetOLEDText "{ text: 'Rebooting...'}"
fi
