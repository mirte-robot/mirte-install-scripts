#!/bin/bash
set -ex

MIRTE_SRC_DIR=/usr/local/src/mirte

# Update
sudo apt update
sudo apt install -y locales python3.8 python3-pip python3-setuptools
{
	# Install locales
	sudo locale-gen "nl_NL.UTF-8"
	sudo locale-gen "en_US.UTF-8"
	sudo update-locale LC_ALL=en_US.UTF-8 LANGUAGE=en_US.UTF-8
} 2>&1 | sed -u 's/^/locales::: /' &
# Install vcstool
cp repos.yaml $MIRTE_SRC_DIR
cp download_repos.sh $MIRTE_SRC_DIR
cd $MIRTE_SRC_DIR
./download_repos.sh

# Install dependecnies to be able to run python3.8
sudo apt install -y

# Set piwheels as pip repo
sudo bash -c "echo '[global]' > /etc/pip.conf"
sudo bash -c "echo 'extra-index-url=https://www.piwheels.org/simple' >> /etc/pip.conf"

{
	# Install telemetrix
	cd $MIRTE_SRC_DIR/mirte-telemetrix-aio
	pip3 install .
} 2>&1 | sed -u 's/^/telemetrix::: /' &
{
	# Install Telemtrix4Arduino project
	# TODO: building STM sometimes fails (and/or hangs)
	cd $MIRTE_SRC_DIR/mirte-install-scripts
	mkdir -p /home/mirte/Arduino/libraries
	mkdir -p /home/mirte/arduino_project/Telemetrix4Arduino
	ln -s $MIRTE_SRC_DIR/mirte-telemetrix4arduino /home/mirte/Arduino/libraries/Telemetrix4Arduino
	ln -s $MIRTE_SRC_DIR/mirte-telemetrix4arduino/examples/Telemetrix4Arduino/Telemetrix4Arduino.ino /home/mirte/arduino_project/Telemetrix4Arduino

	# Install arduino firmata upload script
	cd $MIRTE_SRC_DIR/mirte-install-scripts
	./install_arduino.sh
} 2>&1 | sed -u 's/^/arduino::: /' &

{
	# Install Mirte Python package
	cd $MIRTE_SRC_DIR/mirte-python
	pip3 install .
} 2>&1 | sed -u 's/^/mirte-python::: /' &

{
	# Install Mirte Interface
	cd $MIRTE_SRC_DIR/mirte-install-scripts
	./install_web.sh
} 2>&1 | sed -u 's/^/web::: /' &

{
	# Install Jupyter Notebook
	cd $MIRTE_SRC_DIR/mirte-install-scripts
	./install_jupyter_ros.sh
} 2>&1 | sed -u 's/^/jupyter_ros::: /' &

{
	# Install Mirte ROS packages
	cd $MIRTE_SRC_DIR/mirte-install-scripts
	./install_ROS.sh
} 2>&1 | sed -u 's/^/ROS::: /' &

# Install numpy
pip3 install numpy

sudo apt install -y bluez joystick
# if [ "$(uname -a | grep sunxi)" != "" ]; then
# 	# currently only supporting cheap USB dongles on OrangePi
# 	./install_fake_bt.sh
# fi

# Install Mirte documentation
{
	cd $MIRTE_SRC_DIR/mirte-documentation
	sudo apt install -y python3.8-venv libenchant-dev
	python3 -m venv docs-env
	source docs-env/bin/activate
	pip install docutils==0.16.0 sphinx-tabs==3.2.0 #TODO: use files to freeze versions
	pip install wheel sphinx sphinx-prompt sphinx-rtd-theme sphinxcontrib-spelling sphinxcontrib-napoleon
	mkdir -p _modules/catkin_ws/src
	cd _modules
	ln -s $MIRTE_SRC_DIR/mirte-python .
	cd mirte-python
	pip install .
	source /opt/ros/noetic/setup.bash
	source /home/mirte/mirte_ws/devel/setup.bash
	cd ../../
	make html
	deactivate
} 2>&1 | sed -u 's/^/docs::: /' &
# Install overlayfs and make sd card read only (software)
# sudo apt install -y overlayroot
# Currently only instaling, not enabled
#sudo bash -c "echo 'overlayroot=\"tmpfs\"' >> /etc/overlayroot.conf"
echo "Waiting"
time wait # wait on all the backgrounded stuff
echo "Done installing"
