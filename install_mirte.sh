#!/bin/bash
set -xe

MIRTE_SRC_DIR=/usr/local/src/mirte

# disable ipv6, as not all package repositories are available over ipv6
sudo tee /etc/apt/apt.conf.d/99force-ipv4 <<EOF
Acquire::ForceIPv4 "true";
EOF

# Update
sudo apt update

# Install locales
sudo apt install -y locales
sudo locale-gen "nl_NL.UTF-8"
sudo locale-gen "en_US.UTF-8"
sudo update-locale LC_ALL=en_US.UTF-8 LANGUAGE=en_US.UTF-8

# Install vcstool
cp repos.yaml $MIRTE_SRC_DIR
cp download_repos.sh $MIRTE_SRC_DIR || true
cd $MIRTE_SRC_DIR || exit
./download_repos.sh

# Install dependecnies to be able to run python3.8
sudo apt install -y python3.8 python3-pip python3-setuptools
pip3 install setuptools --upgrade
# Set piwheels as pip repo
sudo bash -c "echo '[global]' > /etc/pip.conf"
sudo bash -c "echo 'extra-index-url=https://www.piwheels.org/simple' >> /etc/pip.conf"

# Install telemetrix
cd $MIRTE_SRC_DIR/mirte-telemetrix-aio || exit
pip3 install .
cd $MIRTE_SRC_DIR/mirte-tmx-pico-aio || exit
pip3 install .

# Install Telemtrix4Arduino project
# TODO: building STM sometimes fails (and/or hangs)
cd $MIRTE_SRC_DIR/mirte-install-scripts || exit
mkdir -p /home/mirte/Arduino/libraries
mkdir -p /home/mirte/arduino_project/Telemetrix4Arduino
ln -s $MIRTE_SRC_DIR/mirte-telemetrix4arduino /home/mirte/Arduino/libraries/Telemetrix4Arduino
ln -s $MIRTE_SRC_DIR/mirte-telemetrix4arduino/examples/Telemetrix4Arduino/Telemetrix4Arduino.ino /home/mirte/arduino_project/Telemetrix4Arduino

# Install arduino firmata upload script
cd $MIRTE_SRC_DIR/mirte-install-scripts || exit
./install_arduino.sh

# Install Mirte Python package
cd $MIRTE_SRC_DIR/mirte-python || exit
pip3 install .

# Install Mirte Interface
cd $MIRTE_SRC_DIR/mirte-install-scripts || exit
./install_web.sh

# Install Jupyter Notebook
cd $MIRTE_SRC_DIR/mirte-install-scripts || exit
./install_jupyter_ros.sh || true # jupyter install fails on orange pi zero 1

# Install Mirte ROS packages
cd $MIRTE_SRC_DIR/mirte-install-scripts || exit
./install_ROS.sh

# Install numpy
pip3 install numpy

sudo apt install -y bluez joystick
if [ "$(uname -a | grep sunxi)" != "" ]; then
	# currently only supporting cheap USB dongles on OrangePi
	./install_fake_bt.sh
fi

# Install Mirte documentation
cd $MIRTE_SRC_DIR/mirte-documentation || exit
sudo apt install -y python3.8-venv libenchant-dev
python3 -m venv docs-env
source docs-env/bin/activate
pip install docutils==0.16.0 sphinx-tabs==3.2.0 #TODO: use files to freeze versions
pip install wheel sphinx sphinx-prompt sphinx-rtd-theme sphinxcontrib-spelling sphinxcontrib-napoleon
mkdir -p _modules/catkin_ws/src
cd _modules || exit
ls
pwd
ln -s $MIRTE_SRC_DIR/mirte-python . || true
cd mirte-python || exit
pip install . || true
source /opt/ros/noetic/setup.bash
source /home/mirte/mirte_ws/devel/setup.bash
cd ../../
make html || true
deactivate

# Install overlayfs and make sd card read only (software)
sudo apt install -y overlayroot
# Currently only instaling, not enabled
#sudo bash -c "echo 'overlayroot=\"tmpfs\"' >> /etc/overlayroot.conf"

# remove force ipv4
sudo rm /etc/apt/apt.conf.d/99force-ipv4 || true
