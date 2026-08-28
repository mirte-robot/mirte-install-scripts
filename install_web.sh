#!/bin/bash
set -xe
MIRTE_SRC_DIR=${MIRTE_SRC_DIR:-/usr/local/src/mirte}
source $MIRTE_SRC_DIR/mirte-install-scripts/tools.sh
# Update
sudo apt update || true

# Install nodeenv
sudo apt install -y python3-pip python3-setuptools python3-wheel
sudo -H pip install nodeenv

# Install backend (node 26.7.0)
nodeenv --node=26.7.0 $MIRTE_SRC_DIR/mirte-web-interface/node_env
. $MIRTE_SRC_DIR/mirte-web-interface/node_env/bin/activate
cd $MIRTE_SRC_DIR/mirte-web-interface/nodejs-backend || exit 1
npm install .
deactivate_node

# Install frontend (node 22.12)
cd $MIRTE_SRC_DIR/mirte-web-interface/vue-frontend || exit 1
nodeenv --node=22.12.0 $MIRTE_SRC_DIR/mirte-web-interface/vue-frontend/node_env
. $MIRTE_SRC_DIR/mirte-web-interface/vue-frontend/node_env/bin/activate
npm install
NUXT_APP_BASE_URL=/ npm run generate
rm -rf node_modules || true
deactivate_node

cd $MIRTE_SRC_DIR/mirte-web-interface
git clone https://github.com/dheera/rosboard.git --single-branch
sudo pip3 install tornado
sudo pip3 install simplejpeg # recommended, but ROSboard can fall back to cv2 or PIL instead

# Install wetty
#cd $MIRTE_SRC_DIR/mirte-web-interface
#npm -g install wetty

# Install strace for linetrace functionality
sudo apt install -y strace
sudo apt install xxd

# Install nginx (as reverse proxy to all services)
sudo apt install -y nginx libnginx-mod-http-auth-pam
sudo cp $MIRTE_SRC_DIR/mirte-install-scripts/nginx.conf /etc/nginx/sites-available/mirte.conf
sudo cp $MIRTE_SRC_DIR/mirte-install-scripts/nginx_login.conf /etc/nginx/nginx_login.conf
sudo ln /etc/nginx/sites-available/mirte.conf /etc/nginx/sites-enabled/
sudo rm /etc/nginx/sites-enabled/default # otherwise this will catch :80 by default

# give nginx access to the passwords file for login
sudo usermod -aG shadow www-data

sudo cp $MIRTE_SRC_DIR/mirte-install-scripts/sites/401.html /var/www/html/

# Add systemd service
add_service mirte-web-interface.service

# install zerotier for better ros2 networking. User will need to manually join the network
curl -s https://install.zerotier.com | sudo bash
# remove zerotier identity as it otherwise will be the same for all devices using the same image
sudo rm /var/lib/zerotier-one/identity.public || true
sudo rm /var/lib/zerotier-one/identity.secret || true
# new identity should be generated on first boot
sudo systemctl disable --now zerotier-one.service || true # fails bc not started with systemd
