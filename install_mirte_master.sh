#!/bin/bash
set -xe

MIRTE_SRC_DIR=/usr/local/src/mirte

if [[ ${type:=""} != "mirte_orangepi3b" ]]; then
	# Fix for wrong sound card
	sudo bash -c 'cat <<EOT >> /etc/asound.conf
defaults.pcm.card 1
defaults.ctl.card 1
EOT'

fi

cd $MIRTE_SRC_DIR/mirte-install-scripts/mirte-master/usb_switch/
sudo apt install libgpiod-dev -y
mkdir build
cd build
cmake ..
make -j
sudo ln -s $MIRTE_SRC_DIR/mirte-install-scripts/services/mirte-usb-switch.service /lib/systemd/system/
sudo systemctl daemon-reload
sudo systemctl stop mirte-usb-switch.service || /bin/true
sudo systemctl start mirte-usb-switch.service
sudo systemctl enable mirte-usb-switch.service
