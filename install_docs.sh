#!/bin/bash

cd $MIRTE_SRC_DIR/mirte-documentation
sudo apt install -y python3.8-venv libenchant-dev
python3 -m venv docs-env
source docs-env/bin/activate
pip install -r requirements.txt
mkdir -p _modules/catkin_ws/src
cd _modules
ln -s $MIRTE_SRC_DIR/mirte-python .
cd mirte-python
pip install .
source /opt/ros/noetic/setup.bash
source /home/mirte/mirte_ws/devel/setup.bash
cd ../../
make html
deactivate
