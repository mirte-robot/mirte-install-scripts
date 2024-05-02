#!/bin/bash
set -xe
mkdir ~/arm_temp
cd ~/arm_temp
sudo systemctl stop mirte-ros
wget https://mirte.arend-jan.com/files/telemetrix/modules2/Telemetrix4RpiPico.uf2
sudo picotool load -f Telemetrix4RpiPico.uf2
git clone -b modules https://github.com/arendjan/tmx-pico-aio.git
cd tmx-pico-aio
pip install .
pip install aioconsole
python3 examples/mirte_master_reset_offset.py
sleep 10
python3 examples/mirte_master_set_ranges_volt.py
sleep 10
python3 examples/mirte_master_check_home.py </dev/tty # ttyp required as this script is piped
sleep 10
cd ~
rm -rf ~/arm_temp
cd ~/mirte_ws/src/mirte-ros-packages/
git pull
catkin build
sudo systemctl start mirte-ros

