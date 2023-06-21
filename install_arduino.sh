#!/bin/bash

MIRTE_SRC_DIR=/usr/local/src/mirte

# Install dependencies
sudo apt install -y git curl binutils libusb-1.0-0

pip3 install -U platformio

curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules | sudo tee /etc/udev/rules.d/99-platformio-udev.rules

ln -s $MIRTE_SRC_DIR/mirte-telemetrix4arduino /home/mirte/Arduino/Telemetrix4Arduino
cd /home/mirte/Arduino/Telemetrix4Arduino
pio run
