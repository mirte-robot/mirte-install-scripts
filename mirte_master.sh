#!/bin/bash
set -xe

MIRTE_SRC_DIR=/usr/local/src/mirte


if [[ ${type:=""} != "mirte_orangepi3b" ]]; then
    # Fix for wrong sound card
 sudo bash -c    'cat <<EOT >> /etc/asound.conf
defaults.pcm.card 1
defaults.ctl.card 1
EOT'

fi
