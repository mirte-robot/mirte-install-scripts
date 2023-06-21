#!/bin/bash

MIRTE_SRC_DIR=/usr/local/src/mirte

# Install dependencies
sudo apt install -y git curl binutils libusb-1.0-0
ls -alh $MIRTE_SRC_DIR
pip3 install -U platformio
echo "export PATH=$PATH:/home/mirte/.local/bin" > /home/mirte/.bashrc
export PATH=$PATH:/home/mirte/.local/bin
curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules | sudo tee /etc/udev/rules.d/99-platformio-udev.rules

mkdir -p /home/mirte/Arduino/Telemetrix4Arduino
ls $MIRTE_SRC_DIR/mirte-telemetrix4arduino -al
ln -s $MIRTE_SRC_DIR/mirte-telemetrix4arduino /home/mirte/Arduino/Telemetrix4Arduino || true
cd $MIRTE_SRC_DIR/mirte-telemetrix4arduino
pio run
