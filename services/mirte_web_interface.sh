#!/bin/bash
set -xe
source /home/mirte/.mirte_settings.sh

source /home/mirte/mirte_ws/install/setup.bash

python3 -m mirte_robot.linetrace &

cd /usr/local/src/mirte/mirte-web-interface/rosboard
./run &

cd /usr/local/src/mirte/mirte-web-interface/
source ./node_env/bin/activate
cd nodejs-backend
npm run backend
