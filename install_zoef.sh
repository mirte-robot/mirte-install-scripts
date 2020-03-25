#!/bin/bash

ZOEF_SRC_DIR=/usr/local/src/zoef

#TODO: find out why this is needed
mount -t proc none /proc

# Update
sudo apt update

# Add zoef user with sudo rights
#TODO: user without homedir (create homedir for user)
useradd -m -G sudo -s /bin/bash zoef
mkdir /home/zoef/workdir
echo -e "zoef_zoef\nzoef_zoef" | passwd zoef
passwd --expire zoef

# Disable ssh root login
sed -i 's/#PermitRootLogin yes/PermitRootLogin no/g' /etc/ssh/sshd_config

# Install vcstool
sudo sh -c 'echo "deb http://packages.ros.org/ros/ubuntu $(lsb_release -sc) main" > /etc/apt/sources.list.d/ros-latest.list'
sudo apt-key adv --keyserver hkp://pool.sks-keyservers.net --recv-key 0xAB17C654
sudo apt-get update
sudo apt-get install -y python3-vcstool

# Download all Zoef repositories
mkdir -p $ZOEF_SRC_DIR
cp repos.yaml $ZOEF_SRC_DIR
cd $ZOEF_SRC_DIR
git config --global credential.helper 'store --file /.my-credentials'
vcs import < repos.yaml --workers 1
rm /.my-credentials

# Install arduino firmata upload script
cd $ZOEF_SRC_DIR/zoef_arduino
./install.sh

# Add zoef to dialout
sudo adduser zoef dialout

# first install NPM, then ROS due to bug (https://github.com/ros/rosdistro/issues/19845)
#TODO: should be part of zoef_interface
sudo apt purge -y ros-*
sudo apt autoremove -y
sudo apt install nodejs npm -y
cd /usr/local/lib
sudo npm install express express-ws node-pty

# Install Zoef Interface
cd $ZOEF_SRC_DIR/web_interface
grep -qxF "export PYTHONPATH=$PYTHONPATH:/home/zoef/web_interface/python" /home/zoef/.bashrc || echo "export PYTHONPATH=$PYTHONPATH:/home/zoef/web_interface/python" >> /home/zoef/.bashrc
sudo ln -s $ZOEF_SRC_DIR/web_interface/python/linetrace.py /home/zoef/workdir
./run_singularity.sh build_dev

# Add systemd service to start ROS nodes
# NOTE: starting singularity image form ssystemd has some issues (https://github.com/sylabs/singularity/issues/1600)
sudo rm /lib/systemd/system/zoef_web_interface.service
sudo bash -c "echo '[Unit]' > /lib/systemd/system/zoef_web_interface.service"
sudo bash -c "echo 'Description=Zoef Web Interface' >> /lib/systemd/system/zoef_web_interface.service"
sudo bash -c "echo 'After=network.target' >> /lib/systemd/system/zoef_web_interface.service"
sudo bash -c "echo 'After=ssh.service' >> /lib/systemd/system/zoef_web_interface.service"
sudo bash -c "echo 'After=network-online.target' >> /lib/systemd/system/zoef_web_interface.service"
sudo bash -c "echo '' >> /lib/systemd/system/zoef_web_interface.service"
sudo bash -c "echo '[Service]' >> /lib/systemd/system/zoef_web_interface.service"
sudo bash -c "echo 'ExecStart=/bin/bash -c \"export NODE_PATH=/usr/local/lib/node_modules/ && nodejs /home/zoef/web_interface/web-shell.js & cd /home/zoef/web_interface/ && singularity run -B app:/app/my_app -B /home/zoef/workdir:/workdir zoef_web_interface 2>&1 | tee\"' >> /lib/systemd/system/zoef_web_interface.service"
sudo bash -c "echo '' >> /lib/systemd/system/zoef_web_interface.service"
sudo bash -c "echo '[Install]' >> /lib/systemd/system/zoef_web_interface.service"
sudo bash -c "echo 'WantedBy=multi-user.target' >> /lib/systemd/system/zoef_web_interface.service"

sudo systemctl daemon-reload
sudo systemctl stop zoef_web_interface || /bin/true
sudo systemctl start zoef_web_interface
sudo systemctl enable zoef_web_interface

# Install Jupyter Notebook
cd $ZOEF_SRC_DIR/zoef_install_scripts
./install_jupyter_ros.sh

# Install pymata
cd $ZOEF_SRC_DIR/zoef_pymata
sudo python setup.py install

# Install Zoef ROS packages
cd $ZOEF_SRC_DIR/zoef_install_scripts
./install_ROS.sh

