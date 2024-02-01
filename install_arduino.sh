#!/bin/bash
set -xe
MIRTE_SRC_DIR=/usr/local/src/mirte

# Install dependencies
sudo apt install -y git curl binutils libusb-1.0-0
ls -alh $MIRTE_SRC_DIR
pip3 install -U platformio
echo "export PATH=$PATH:/home/mirte/.local/bin" >/home/mirte/.bashrc
export PATH=$PATH:/home/mirte/.local/bin
curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules | sudo tee /etc/udev/rules.d/99-platformio-udev.rules

mkdir -p /home/mirte/Arduino/Telemetrix4Arduino
ls $MIRTE_SRC_DIR/mirte-telemetrix4arduino -al
ln -s $MIRTE_SRC_DIR/mirte-telemetrix4arduino /home/mirte/Arduino/Telemetrix4Arduino || true
cd $MIRTE_SRC_DIR/mirte-telemetrix4arduino || exit
pio run -e robotdyn_blackpill_f303cc -e nanoatmega328new -e nanoatmega328

# pico stuff
sudo apt install cmake gcc-arm-none-eabi libnewlib-arm-none-eabi build-essential libusb-1.0-0-dev libstdc++-arm-none-eabi-newlib -y
cd $MIRTE_SRC_DIR/pico-sdk/ || exit
git submodule update --init
echo "export PICO_SDK_PATH=$MIRTE_SRC_DIR/pico-sdk/" >/home/mirte/.bashrc
export PICO_SDK_PATH=$MIRTE_SRC_DIR/pico-sdk/
cd $MIRTE_SRC_DIR/mirte-telemetrix4rpipico || exit
mkdir build
cd build || exit
cmake ..
make

# TODO: add picotool and install it:
# git clone https://github.com/raspberrypi/picotool.git --branch master --progress
# cd picotool
# mkdir build
# cd build
# export PICO_SDK_PATH=~/pico/pico-sdk
# cmake ../
# make
# make install
