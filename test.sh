#!/bin/bash

echo "Skipping installation of Pico tools"
echo "Only installing tools to upload to Pico with default uf2"
# download latest picotool for current arch linux
arch="aarch64"
curl -s https://api.github.com/repos/raspberrypi/pico-sdk-tools/releases/latest | grep -F "browser_download_url" | awk -F\" '{print $4}' | grep "picotool-.*-$arch-lin.tar.gz" | wget -i - -O /tmp/picotool-latest-$arch-lin.tar.gz
# Check that the file was downloaded and is a valid tar.gz
if [ ! -s /tmp/picotool-latest-$arch-lin.tar.gz ]; then
	echo "Error: Failed to download picotool tarball for architecture $arch."
	exit 1
fi
if ! gzip -t /tmp/picotool-latest-$arch-lin.tar.gz 2>/dev/null; then
	echo "Error: Downloaded picotool tarball is not a valid gzip file."
	exit 1
fi
