#!/bin/bash
# set -xe

# MIRTE_SRC_DIR=${MIRTE_SRC_DIR:-/usr/local/src/mirte}
# # This script copies the image from the SD card to the eMMC, so that the system can boot from eMMC instead of SD card.
# # It is called from the first boot, and will reboot the system after copying the image.

# # settings passed with parameters, default set here:
# TARGET_DEVICE=${1:-/dev/mmcblk1}
# SOURCE_DEVICE=${2:-/dev/mmcblk0}

# function copy_to_emmc() {
# 	# run armbian-install with expect to automate the process, as it requires user input
# 	# we expect after a few seconds a prompt with 2 Boot from eMMC, and must run this
# 	expect <<EOF
# set timeout -1
# spawn armbian-install
# expect "Boot from eMMC"
# sleep 2
# send "2\r"
# expect "This script will erase"
# sleep 2
# send "y\r"
# expect "Select filesystem"
# # sleep 1s
# sleep 2
# send "1\r"
# expect "All done"
# sleep 2
# send "E\r"
# expect eof
# EOF

# }

# function copy_to_sd() {
# 	# run armbian-install with expect to automate the process, as it requires user input
# 	# we expect after a few seconds a prompt with 1 Boot from SD card, and must run this
# 	expect <<EOF
# set timeout -1
# spawn armbian-install
# expect "Boot from SD card"
# sleep 2
# send "2\r"
# expect "This script will erase"
# sleep 2
# send "y\r"
# expect "Select filesystem"
# # sleep 1s
# sleep 2
# send "1\r"
# expect "All done"
# sleep 2
# send "E\r"
# expect eof
# EOF
# }

# function copy_to_nvme() {
# 	# run armbian-install with expect to automate the process, as it requires user input
# 	# option 4, boot from mtd flash
# 	# skip wipe partitions
# 	# select 1 for dev
# 	# continue
# 	# 1 for ext4
# 	# y for bootloader writing

# 	TODO: This is just not really robust enough.

# }
