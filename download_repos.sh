#!/bin/bash
set -xe
# Install vcstool
ROS_APT_SOURCE_VERSION=$(curl -s https://api.github.com/repos/ros-infrastructure/ros-apt-source/releases/latest | grep -F "tag_name" | awk -F\" '{print $4}')
curl -L -o /tmp/ros2-apt-source.deb "https://github.com/ros-infrastructure/ros-apt-source/releases/download/${ROS_APT_SOURCE_VERSION}/ros2-apt-source_${ROS_APT_SOURCE_VERSION}.$(. /etc/os-release && echo $VERSION_CODENAME)_all.deb"
sudo apt install /tmp/ros2-apt-source.deb
sudo apt update
sudo apt-get install -y python3-vcstool

# Download all Mirte repositories
vcs import --workers 1 <repos.yaml #TODO: get yaml file as parameter

# Initialize the submodule of mirte-telemetrix-cpp
if [ -d ./mirte-telemetrix-cpp ]; then
	cd mirte-telemetrix-cpp
	git submodule update --init --recursive
	cd -
fi

# TODO: set remote to gitlab when checkout from local
