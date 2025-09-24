#!/bin/bash

set -xe
sudo nmcli d wifi connect smartfridge password kaasblokje
sudo apt update
sudo apt upgrade -y
export NONINTERACTIVE=1
export ROS_INSTALL_CHOICE=1
wget -c https://raw.githubusercontent.com/ArendJan/ros2_oneline_install/main/ros2_install_humble.sh && chmod +x ./ros2_install_humble.sh && ./ros2_install_humble.sh || true

# add the ros2 path to the bashrc
echo "export ROS_DOMAIN_ID=1" >>~/.bashrc || true
echo "source /opt/ros/humble/setup.bash" >>~/.bashrc || true

sudo snap install --classic code
