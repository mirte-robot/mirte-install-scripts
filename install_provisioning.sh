#!/bin/bash
set -xe

MIRTE_SRC_DIR=${MIRTE_SRC_DIR:-/usr/local/src/mirte}

cd $MIRTE_SRC_DIR/mirte-install-scripts/provisioning

pip install -r requirements.txt
source $MIRTE_SRC_DIR/mirte-install-scripts/tools.sh
# sudo ln -s "$(realpath ./mirte-provisioning.service)" /etc/systemd/system/
# sudo systemctl daemon-reload
# sudo systemctl enable mirte-provisioning.service
# sudo systemctl start mirte-provisioning.service || true # wont start when compiling image
add_
