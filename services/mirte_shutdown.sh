#!/bin/bash
set -xe
# Don't turn off the relay if the system is rebooting
# TODO: does not work if ros is not running
# if ! systemctl list-jobs | grep -q -e "reboot.target.*start"; then
# 	echo "not rebooting"
# else
# 	printf "Rebooting\n"
# 	exit
# fi

touch /home/mirte/shutdown
source /home/mirte/mirte_ws/devel/setup.bash
rosservice call /mirte/shutdown "data: false"
# touch /home/mirte/shutdown_done
sleep 10
