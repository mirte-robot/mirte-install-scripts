#!/bin/bash

set -x
MIRTE_SRC_DIR=/usr/local/src/mirte
ping -c 10 a.arend-jan.com
# Make sure there are no conflicting hcdp-servers
sudo apt install -y dnsmasq-base
ping -c 10 ab.arend-jan.com
systemctl disable hostapd
ping -c 10 ac.arend-jan.com
sed -i 's/#DNSStubListener=yes/DNSStubListener=no/g' /etc/systemd/resolved.conf
ping -c 10 ad.arend-jan.com
# Install netplan (not installed on armbian) and networmanager (not installed by Raspberry)
sudo apt install -y netplan.io
ping -c 10 ae.arend-jan.com
sudo apt install -y network-manager
ping -c 10 af.arend-jan.com
sudo cp $MIRTE_SRC_DIR/mirte-install-scripts/50-cloud-init.yaml /etc/netplan/
ping -c 10 ag.arend-jan.com
sudo netplan apply
sleep 10
ping -c 5 8.8.8.8
ping -c 10 ah.arend-jan.com
sudo apt purge -y ifupdown
ping -c 10 ai.arend-jan.com

# Fix for bug in systemd-resolved
# (https://askubuntu.com/questions/973017/wrong-nameserver-set-by-resolvconf-and-networkmanager)
# For the installation we need 8.8.8.8, but linking will be done in network_setup.sh
sudo rm -rf /etc/resolv.conf
ping -c 10 aj.arend-jan.com
sudo bash -c 'echo "nameserver 8.8.8.8" > /etc/resolv.conf'
ping -c 10 ak.arend-jan.com
# Install wifi-connect
MY_ARCH=$(arch)
ping -c 10 al.arend-jan.com
if [[ $MY_ARCH == "armv7l" ]]; then MY_ARCH="rpi"; fi
wget https://github.com/balena-os/wifi-connect/releases/download/v4.4.6/wifi-connect-v4.4.6-linux-"$(echo "$MY_ARCH")".tar.gz
tar -xf wifi-connect*
ping -c 10 am.arend-jan.com
sudo mv wifi-connect /usr/local/sbin
ping -c 10 an.arend-jan.com
rm wifi-connect*
ping -c 10 ao.arend-jan.com
# Added systemd service to account for fix: https://askubuntu.com/questions/472794/hostapd-error-nl80211-could-not-configure-driver-mode
sudo rm /lib/systemd/system/mirte-ap.service
sudo ln -s $MIRTE_SRC_DIR/mirte-install-scripts/services/mirte-ap.service /lib/systemd/system/

sudo systemctl daemon-reload
ping -c 10 ap.arend-jan.com
sudo systemctl stop mirte-ap || /bin/true
sudo systemctl start mirte-ap
sudo systemctl enable mirte-ap
ping -c 10 aq.arend-jan.com
# Added systemd service to check on boot error for OPi
sudo rm /lib/systemd/system/mirte-wifi-watchdog.service
sudo ln -s $MIRTE_SRC_DIR/mirte-install-scripts/services/mirte-wifi-watchdog.service /lib/systemd/system/

sudo systemctl daemon-reload
sudo systemctl stop mirte-wifi-watchdog || /bin/true
sudo systemctl start mirte-wifi-watchdog
sudo systemctl enable mirte-wifi-watchdog
ping -c 10 ar.arend-jan.com
# Install avahi
sudo apt install -y libnss-mdns
ping -c 10 as.arend-jan.com
sudo apt install -y avahi-utils avahi-daemon
ping -c 10 at.arend-jan.com
sudo apt install -y avahi-utils avahi-daemon # NOTE: Twice, since regular apt installation on armbian fails (https://forum.armbian.com/topic/10204-cant-install-avahi-on-armbian-while-building-custom-image/)
ping -c 10 au.arend-jan.com
# Disable lo interface for avahi
sed -i 's/#deny-interfaces=eth1/deny-interfaces=lo/g' /etc/avahi/avahi-daemon.conf
ping -c 10 av.arend-jan.com
# Install dependecies needed for setup script
sudo apt install -y inotify-tools wireless-tools
ping -c 10 aw.arend-jan.com
# Disable ssh root login
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config
ping -c 10 a.arend-jan.com
# Install usb_ethernet script from EV3
wget https://raw.githubusercontent.com/ev3dev/ev3-systemd/ev3dev-buster/scripts/ev3-usb.sh -P $MIRTE_SRC_DIR/mirte-install-scripts
sudo chmod +x $MIRTE_SRC_DIR/mirte-install-scripts/ev3-usb.sh
sudo chown mirte:mirte $MIRTE_SRC_DIR/mirte-install-scripts/ev3-usb.sh
sudo bash -c 'echo "libcomposite" >> /etc/modules'

# Generate wifi password (TODO: generate random password and put on NTFS)
if [ ! -f /home/mirte/.wifi_pwd ]; then
	bash -c 'echo mirte_mirte > /home/mirte/.wifi_pwd'
fi

# Allow wifi_pwd to be modified using the web interface
sudo chmod 777 /home/mirte/.wifi_pwd

# Add hostname and make it writable
sudo bash -c 'echo "Mirte-XXXXXX" > /etc/hostname'
sudo chmod 777 /etc/hostname

# Fix for wpa_supplicant error
sudo bash -c "echo 'match-device=driver:wlan0' >> /etc/NetworkManager/NetworkManager.conf"

# Reboot after kernel panic
# The OPi has a fairly unstable wifi driver which might
# panic the kernel (at boot). Instead of waiting an unkown
# time and reboot manually, we will reboot automatically
sudo bash -c 'echo "kernel.panic = 10" > /etc/sysctl.conf'
