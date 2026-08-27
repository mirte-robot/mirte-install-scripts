#!/bin/bash

# some functions to help with the setup

add_rc() {
	lines=$1

	grep -qxF "$lines" ~/.bashrc || echo "$lines" >>~/.bashrc

	# if we have a second argument, we use that as lines to add to zshrc, otherwise keep the same as bashrc
	if [ -z "$2" ]; then
		lines=$1
	else
		lines=$2
	fi
	grep -qxF "$lines" ~/.zshrc || echo "$lines" >>~/.zshrc
}

add_mirte_settings() {
	lines=$1
	echo "$lines" >>~/.mirte_settings.sh
}

update_machine_config() {
	key=$1
	value=$2
	# open the machine_config.yaml file and update the key with the value, if the key does not exist, add it to the end of the file
	machine_config_file=$MIRTE_SRC_DIR/provisioning/store/machine_config.yaml
	yq -i ".$key = \"$value\"" "$machine_config_file"
}

function add_service() {
	service_name=$1
	# check if service file exists in install scripts, if not, exit with error
	if [[ ! -f $MIRTE_SRC_DIR/mirte-install-scripts/services/$service_name ]]; then
		echo "Service file $service_name does not exist in $MIRTE_SRC_DIR/mirte-install-scripts/services/"
		exit 1
	fi
	sudo rm -f /lib/systemd/system/$service_name
	sudo ln -s $MIRTE_SRC_DIR/mirte-install-scripts/services/$service_name /lib/systemd/system/
	sudo systemctl daemon-reload
	sudo systemctl stop $service_name || /bin/true
	sudo systemctl start $service_name
	sudo systemctl enable $service_name
}
