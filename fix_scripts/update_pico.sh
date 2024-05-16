#!/bin/bash
set -xe
mkdir test || true
cd test
wget -N https://mirte.arend-jan.com/files/telemetrix/release/Telemetrix4RpiPico.uf2.sha256sum
wget -N https://mirte.arend-jan.com/files/telemetrix/release/Telemetrix4RpiPico.uf2
wget -N https://mirte.arend-jan.com/files/telemetrix/release/Telemetrix4RpiPico.bin.sha256sum
sudo picotool info Telemetrix4RpiPico.uf2
sha256sum -c Telemetrix4RpiPico.uf2.sha256sum || exit 1
sudo picotool load -f Telemetrix4RpiPico.uf2
sleep 2
sudo picotool save -f Telemetrix4RpiPico.bin
sha256sum -c Telemetrix4RpiPico.bin.sha256sum || exit 1

cd /usr/local/src/mirte/mirte-tmx-pico-aio
git pull
pip install .
pip install aioconsole
cd ~/mirte_ws/src/mirte-ros-packages/
git pull
catkin build