#!/bin/bash
set -xe
MIRTE_SRC_DIR=${MIRTE_SRC_DIR:-/usr/local/src/mirte}

# VScode in 2 parts:
# - vscode remote server, when using the ssh plugin from another computer
#   preloading as the robot (and computer) might not have internet access later
# - 'vscode' website

# First part: https://github.com/b01/dl-vscode-server
cd $MIRTE_SRC_DIR || exit
mkdir vscode || true
cd vscode || exit
ARCH="x64"
if [[ "$(uname -m)" == "aarch64" ]]; then
	ARCH="arm64"
fi
curl -L https://raw.githubusercontent.com/b01/dl-vscode-server/refs/tags/1.0.1/download-vs-code.sh | bash -s -- "linux" $ARCH

# Second part:
mkdir -p $MIRTE_SRC_DIR/vscode || true
cd $MIRTE_SRC_DIR/vscode || exit
sudo -u mirte bash -c "curl -fsSL https://code-server.dev/install.sh | sh"
sudo -u mirte bash -c "mkdir -p ~/.config/code-server && cp $MIRTE_SRC_DIR/mirte-install-scripts/config/code_server_config.yaml ~/.config/code-server/config.yaml" || true
sudo systemctl enable code-server@mirte.service || true # Added by the code-server install script
