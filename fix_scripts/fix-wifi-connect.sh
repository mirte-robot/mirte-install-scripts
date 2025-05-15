#!/bin/bash
set -xe
# create tmp directory
tmp_dir=$(mktemp -d)

cd $tmp_dir
MY_ARCH=$(arch)
if [[ "$MY_ARCH" == "aarch64" ]]; then
	wget https://github.com/ArendJan/balena-os-wifi-connect/releases/download/fix-zerotier/wifi-connect-aarch64-unknown-linux-gnu.zip
fi
if [[ "$MY_ARCH" == "armv7l" ]]; then
	wget https://github.com/ArendJan/balena-os-wifi-connect/releases/download/fix-zerotier/wifi-connect-armv7-unknown-linux-gnueabihf.zip
fi
unzip wifi-connect*
sudo mv wifi-connect /usr/local/sbin
rm wifi-connect*
