#!/bin/bash
set -xe
sudo systemctl stop mirte-ros
mkdir ~/update_all || true
cd ~/update_all
wget -N https://mirte.arend-jan.com/files/telemetrix/release/Telemetrix4RpiPico.uf2.sha256sum
wget -N https://mirte.arend-jan.com/files/telemetrix/release/Telemetrix4RpiPico.uf2
wget -N https://mirte.arend-jan.com/files/telemetrix/release/Telemetrix4RpiPico.bin.sha256sum
sudo picotool info Telemetrix4RpiPico.uf2
sha256sum -c Telemetrix4RpiPico.uf2.sha256sum || exit 1
sudo picotool load -f Telemetrix4RpiPico.uf2
sleep 2
sudo picotool save -f Telemetrix4RpiPico.bin
sha256sum -c Telemetrix4RpiPico.bin.sha256sum || exit 1
cd ~
rm -rf ~/update_all
cd /usr/local/src/mirte/mirte-tmx-pico-aio
git pull
pip install .
pip install aioconsole
cd ~/mirte_ws/src/mirte-ros-packages/
git stash # save students changes
git pull
git stash pop || true # apply students changes
git status
echo "Resolve any merge conflicts before reboot!!!" # resolve merge conflicts before reboot
catkin build

cd /usr/local/src/mirte/mirte-install-scripts/
git pull
sudo systemctl daemon-reload
sudo systemctl start mirte-ros
sudo touch /forcefsck

sync