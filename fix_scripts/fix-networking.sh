#!/bin/bash
set -xe
echo "Starting networking fix script"
sudo apt update
# sudo apt-get upgrade -y "ros-humble-
cd /home/mirte/mirte_ws/src/mirte-ros-packages/
git fetch --all
git pull
git switch develop || true
cd /home/mirte/mirte_ws/src/ros2_astra_camera/
git fetch --all
git pull
cd /home/mirte/mirte_ws/
source ./install/setup.bash
colcon build --symlink-install --packages-select mirte_fastdds_discovery_setup astra_camera
source /home/mirte/mirte_ws/install/setup.bash
# add MIRTE_FASTDDS=true to .mirte_settings.sh
echo "MIRTE_FASTDDS=true" >> /home/mirte/.mirte_settings.sh

cd /usr/local/src/mirte/mirte-install-scripts/
git fetch --all
git pull
echo "rebooting in 10 seconds"
sleep 10
sudo reboot now