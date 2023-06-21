#!/bin/bash
set -ex

MIRTE_SRC_DIR=/usr/local/src/mirte
UPDATE=false


# Update
sudo apt update
sudo apt install -y locales python3.8 python3-pip python3-setuptools
{
	# Install locales
	sudo locale-gen "nl_NL.UTF-8"
	sudo locale-gen "en_US.UTF-8"
	sudo update-locale LC_ALL=en_US.UTF-8 LANGUAGE=en_US.UTF-8
	echo "done locale"
} 2>&1 | sed -u 's/^/locales::: /' &
# Install vcstool
pwd
ls -alh
. ./download_repos.sh

# Install dependecnies to be able to run python3.8

# Set piwheels as pip repo
sudo bash -c "echo '[global]' > /etc/pip.conf"
sudo bash -c "echo 'extra-index-url=https://www.piwheels.org/simple' >> /etc/pip.conf"

{
	# Install telemetrix
	cd $MIRTE_SRC_DIR/mirte-telemetrix-aio
	pip3 install .
	echo "done telemetrix"
} 2>&1 | sed -u 's/^/telemetrix::: /' &

{
		cd $MIRTE_SRC_DIR/mirte-install-scripts

	. ./install_arduino.sh
	echo "done arduino"
} 2>&1 | sed -u 's/^/arduino::: /' &

if false; then
	{
		# Install Mirte Python package
		cd $MIRTE_SRC_DIR/mirte-python
		pip3 install .
		echo "done mirte-python"
	} 2>&1 | sed -u 's/^/mirte-python::: /' &

	{
		# Install Mirte Interface
		cd $MIRTE_SRC_DIR/mirte-install-scripts
		. ./install_web.sh
		echo "done web"
	} 2>&1 | sed -u 's/^/web::: /' &

	{
		# Install Jupyter Notebook
		cd $MIRTE_SRC_DIR/mirte-install-scripts
		. ./install_jupyter_ros.sh
		echo "done jupyter_ros"
	} 2>&1 | sed -u 's/^/jupyter_ros::: /' &

	{
		# Install Mirte ROS packages
		cd $MIRTE_SRC_DIR/mirte-install-scripts
		. ./install_ROS.sh
		echo "done ROS"
	} 2>&1 | sed -u 's/^/ROS::: /' &

	# Install numpy
	pip3 install numpy

	sudo apt install -y bluez joystick
	# if [ "$(uname -a | grep sunxi)" != "" ]; then
	# 	# currently only supporting cheap USB dongles on OrangePi
	# 	. ./install_fake_bt.sh
	# fi

	# Install Mirte documentation
	{
		. ./install_docs.sh
		echo "done docs"
	} 2>&1 | sed -u 's/^/docs::: /' &
# Install overlayfs and make sd card read only (software)
# sudo apt install -y overlayroot
# Currently only instaling, not enabled
#sudo bash -c "echo 'overlayroot=\"tmpfs\"' >> /etc/overlayroot.conf"
fi
echo "Waiting"
time wait # wait on all the backgrounded stuff
echo "Done installing"
