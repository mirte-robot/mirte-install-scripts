#!/bin/bash


# cloud init setup for mirte
set -e
MIRTE_SRC_DIR=/home/mirte/mirte_src


sudo apt install cloud-init -y
sudo cp $MIRTE_SRC_DIR/mirte-install-scripts/cloud-init/mirte-cloud-config.yaml /etc/cloud/cloud.cfg 
sudo cloud-init clean --logs
sudo cloud-init init
sudo cloud-init modules --mode=config
sudo cloud-init modules --mode=final