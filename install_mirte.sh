#!/bin/bash
set -ex

MIRTE_SRC_DIR=/usr/local/src/mirte

# Update
sudo apt update

# Install locales
sudo apt install -y locales
sudo locale-gen "nl_NL.UTF-8"
sudo locale-gen "en_US.UTF-8"
sudo update-locale LC_ALL=en_US.UTF-8 LANGUAGE=en_US.UTF-8

# Install vcstool
cp repos.yaml $MIRTE_SRC_DIR
cp download_repos.sh $MIRTE_SRC_DIR
cd $MIRTE_SRC_DIR
./download_repos.sh

# Install dependecnies to be able to run python3.8
sudo apt install -y python3.8 python3-pip python3-setuptools

# Install Mirte Interface
cd $MIRTE_SRC_DIR/mirte-install-scripts
./install_web.sh

# Install Jupyter Notebook
cd $MIRTE_SRC_DIR/mirte-install-scripts
./install_jupyter_ros.sh

# Install telemetrix
cd $MIRTE_SRC_DIR/mirte-telemetrix-aio
pip3 install .

# Install Telemtrix4Arduino project
cd $MIRTE_SRC_DIR/mirte-install-scripts
mkdir -p /home/mirte/Arduino/libraries
mkdir -p /home/mirte/arduino_project/Telemetrix4Arduino
ln -s $MIRTE_SRC_DIR/mirte-telemetrix4arduino /home/mirte/Arduino/libraries/Telemetrix4Arduino
ln -s $MIRTE_SRC_DIR/mirte-telemetrix4arduino/examples/Telemetrix4Arduino/Telemetrix4Arduino.ino /home/mirte/arduino_project/Telemetrix4Arduino

# Install arduino firmata upload script
cd $MIRTE_SRC_DIR/mirte-install-scripts
./install_arduino.sh

# Install Mirte ROS packages
cd $MIRTE_SRC_DIR/mirte-install-scripts
./install_ROS.sh

sudo apt install -y bluez joystick
if [ "$(uname -a | grep sunxi)" != "" ]; then
  # currently only supporting cheap USB dongles on OrangePi
  ./install_fake_bt.sh
fi

# Install Mirte Python package
cd $MIRTE_SRC_DIR/mirte-python
pip3 install .

# Install numpy
pip3 install numpy
