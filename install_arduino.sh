#!/bin/bash

MIRTE_SRC_DIR=/usr/local/src/mirte

# Install dependencies
$UPDATE || sudo apt install -y git curl binutils libusb-1.0-0
ls -alh $MIRTE_SRC_DIR
pip3 install -U platformio
$UPDATE || echo "export PATH=$PATH:/home/mirte/.local/bin" >/home/mirte/.bashrc
export PATH=$PATH:/home/mirte/.local/bin
$UPDATE || curl -fsSL https://raw.githubusercontent.com/platformio/platformio-core/develop/platformio/assets/system/99-platformio-udev.rules | sudo tee /etc/udev/rules.d/99-platformio-udev.rules

$UPDATE || mkdir -p /home/mirte/Arduino/Telemetrix4Arduino
ls $MIRTE_SRC_DIR/mirte-telemetrix4arduino -al
$UPDATE || ln -s $MIRTE_SRC_DIR/mirte-telemetrix4arduino /home/mirte/Arduino/Telemetrix4Arduino || true
cd $MIRTE_SRC_DIR/mirte-telemetrix4arduino || exit
pio run -e robotdyn_blackpill_f303cc -e nanoatmega328new -e nanoatmega328
