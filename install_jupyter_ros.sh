#!/bin/bash

MIRTE_SRC_DIR=/usr/local/src/mirte

# install basic python tools
sudo apt install -y python3 python3-venv python3-dev git libffi-dev

# create and activate virtualenv
# Due to a build error on numpy we need to install numpy and
# padnas globally and us it in the virtual environment
cd /home/mirte || exit
sudo apt install -y python3-numpy python3-pandas
python3 -m venv jupyter --system-site-packages
source /home/mirte/jupyter/bin/activate

# install jupyros
pip3 install wheel
pip3 install markupsafe==2.0.1
pip3 install jupyter bqplot==0.12.18 pyyaml ipywidgets
pip3 install jupyros
jupyter nbextension enable --py --sys-prefix jupyros
deactivate
sudo chown -R mirte:mirte /home/mirte/jupyter

# TEMP: download examples
git clone https://github.com/RoboStack/jupyter-ros.git
sudo chown -R mirte:mirte /home/mirte/jupyter-ros

# Add systemd service to start jupyter
sudo rm /lib/systemd/system/mirte-jupyter.service
sudo ln -s $MIRTE_SRC_DIR/mirte-install-scripts/services/mirte-jupyter.service /lib/systemd/system/
