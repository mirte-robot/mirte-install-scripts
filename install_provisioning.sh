#!/bin/bash
set -xe

MIRTE_SRC_DIR=${MIRTE_SRC_DIR:-/usr/local/src/mirte}

cd $MIRTE_SRC_DIR/mirte-install-scripts/provisioning

# install provisioning pkgs, need to be done as root, otherwise missing pkgs.
sudo pip install -r requirements.txt
source $MIRTE_SRC_DIR/mirte-install-scripts/tools.sh
# provisioning service, runs on first boot and sets up the robot according to the machine_config.json file
add_service mirte-provisioning.service
