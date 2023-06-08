#!/bin/bash
set -x #echo on

# sudo apt update
sudo apt install cmake gcc-arm-none-eabi libnewlib-arm-none-eabi build-essential libusb-1.0-0-dev -y
cd ~/
mkdir pico
cd pico
git clone https://github.com/raspberrypi/pico-sdk.git --branch master --progress
cd pico-sdk
git submodule update --init --progress
cd ~/pico
git clone https://github.com/raspberrypi/picotool.git --branch master --progress
cd picotool
mkdir build
cd build
export PICO_SDK_PATH=~/pico/pico-sdk
cmake ../
make
make install

cd ~/
git clone https://github.com/arendjan/Telemetrix4RpiPico.git --progress
cd Telemetrix4RpiPico
mkdir build
cd build
cmake ..
make
sudo picotool load -f Telemetrix4RpiPico.uf2
