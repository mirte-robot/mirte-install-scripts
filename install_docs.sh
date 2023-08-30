#!/bin/bash

cd $MIRTE_SRC_DIR/mirte-documentation || exit
$UPDATE || sudo apt install -y python3.8-venv libenchant-dev
$UPDATE || python3 -m venv docs-env
source docs-env/bin/activate
pip install -r requirements.txt
$UPDATE || mkdir -p _modules/catkin_ws/src
cd _modules || exit
$UPDATE || ln -s $MIRTE_SRC_DIR/mirte-python .
cd mirte-python || exit
pip install .
source /opt/ros/noetic/setup.bash
source /home/mirte/mirte_ws/devel/setup.bash
cd ../../
make html
deactivate
