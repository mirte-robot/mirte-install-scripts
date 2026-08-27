import subprocess
import yaml
import os
from deepdiff import DeepDiff
import nmcli
import asyncio
import provisioning_module
from machine_config_mods import ap as machine_config_ap
from machine_config_mods import copy_image as machine_config_copy_image
from machine_config_mods import cleanup_overlay as machine_config_cleanup_overlay
from machine_config_mods import shell as machine_config_shell

needs_mount = True


# settings from /mnt/mirte/machine_config.yaml are read
# settings are applied as possible
# some are compared to the ones in ./store/machine_config.yaml to check if they have been changed
# after applying, they are stored in ./store/machine_config.yaml for the next boot.


prev_config_file = os.path.join(
    os.path.dirname(os.path.realpath(__file__)), "store/machine_config.yaml"
)
print(prev_config_file)


class MachineConfig(provisioning_module.ProvisionModule):

    needs_mount = True
    hostname = "Mirte-XXXXX"

    def start(self, mount_point, loop):
        self.stopped = False
        self.config_file = f"{mount_point}/machine_config.yaml"
        if not os.path.isfile(self.config_file):
            print("No machine_config configuration, stopping config provisioning")
            # copy store/machine_config.yaml to /mnt/mirte/machine_config.yaml
            subprocess.run(["cp", prev_config_file, self.config_file], check=True)
            # self.write_back_configuration({}, self.config_file)
            # return
        # use hostnamectl to set new hostname
        self.hostname = subprocess.run(
            ["hostnamectl", "hostname"], check=True, capture_output=True
        )
        print(self.hostname)
        self.hostname = self.hostname.stdout.decode().strip()
        print(f"Current hostname: {self.hostname}")
        # with open("/etc/hostname", "r") as file:
        #     old_name = file.readlines()[0].strip()
        #     self.hostname = old_name
        with open(self.config_file, "r") as file:
            configuration = yaml.safe_load(file)
        with open(prev_config_file, "r") as file:
            prev_configuration = yaml.safe_load(
                file
            )  # this file should have all the configuration options
        configuration = {**prev_configuration, **configuration}
        if "hostname" in configuration:
            self.set_hostname(configuration["hostname"], prev_configuration["hostname"])
        if "access_points" in configuration:
            self.ap_config = machine_config_ap.machine_config_ap(self.hostname, loop)
            self.ap_config.access_points(configuration)
        if "shell" in configuration:
            machine_config_shell.set_shell(configuration)
        self.set_passwords(configuration, prev_configuration)
        # machine_config_copy_image.install_system(configuration=configuration)
        self.set_mirte_type(configuration=configuration)
        self.start_cleanup_overlay(configuration=configuration)
        machine_config_cleanup_overlay.cleanup_overlayfs(
            configuration, self.overwrite_main_config
        )
        # todo: if usb is installed with bootable and img, nuke first part of this disk and reboot
        self.write_back_configuration(configuration, self.config_file)
        self.store_prev_config(configuration, prev_config_file)

    def start_cleanup_overlay(self, configuration):
        def overwrite_cleanup_overlay_config(configuration, overwrite_key):
            self.overwrite_main_config(configuration, self.config_file, overwrite_key)

        machine_config_cleanup_overlay.cleanup_overlayfs(
            configuration, overwrite_cleanup_overlay_config
        )

    def stop(self):
        if hasattr(self, "ap_config"):
            self.ap_config.stop()

    def set_hostname(self, new_hostname, curr_set_hostname):

        if new_hostname == curr_set_hostname:
            return
        with open("/etc/hostname", "r") as file:
            old_name = file.readlines()[0].strip()
            self.hostname = old_name
            if new_hostname == old_name:
                return
        print(f"Renaming from {old_name} to {new_hostname}")
        out = subprocess.run(
            ["hostnamectl", "set-hostname", new_hostname],
            check=True,
            capture_output=True,
        )
        print(out.stdout.decode())
        # add new hostname to /etc/hosts, replacing old hostname
        with open("/etc/hosts", "r") as file:
            lines = file.readlines()
        new_lines = []
        overwritten = False
        for line in lines:
            if line.endswith(f" {old_name}\n"):
                new_lines.append(line.replace(f" {old_name}\n", f" {new_hostname}\n"))
                overwritten = True
            else:
                new_lines.append(line)
        if not overwritten:
            new_lines.append(f"127.0.0.1 {new_hostname}\n")
        with open("/etc/hosts", "w") as file:
            file.writelines(new_lines)
        self.hostname = new_hostname

    def set_passwords(self, curr_config, prev_config):
        if "password" in curr_config:
            self.set_password(curr_config["password"], prev_config["password"])
        if "root_password" in curr_config:
            self.set_root_password(
                curr_config["root_password"], prev_config["root_password"]
            )

    def set_root_password(self, new_password, prev_set_password):
        # todo
        # usermod --password $(echo MY_NEW_PASSWORD | openssl passwd -1 -stdin) USERNAME
        if new_password == prev_set_password:
            # No need to update it and possibly the user edited it already by using the passwd command
            return
        # if password starts with dollar sign, then it is already encrypted, so do not encrypt it again, just set it
        if new_password.startswith("$"):
            print(f"Setting root password to already encrypted password")
            o = os.system(f"sudo usermod --password '{new_password}' root")
            print(o)
            return
        print(f'Changing root password to "{new_password}"')
        command = f'echo "root:{new_password}" | sudo chpasswd'
        o = os.system(command)
        print(o)
        print("Root password changed.")
        pass

    def set_password(self, new_password, prev_set_password):
        if new_password == prev_set_password:
            # No need to update it and possibly the user edited it already by using the passwd command
            return
        if (
            len(new_password) < 8
        ):  # when changing as the mirte user, there are some checks, when changing as root, no checks
            print(
                "Password should be at least 8 characters long, skipping password change"
            )
            return
        print(f'Changing password to "{new_password}"')
        o = os.system(f"sudo chpasswd mirte:{new_password}")
        print(o)

    def overwrite_main_config(self, configuration, config_file, overwrite_key):

        # use yq to update config file
        subprocess.run(f"yq -i '.{overwrite_key} = \"{configuration[overwrite_key]}\"' {config_file}", shell=True, check=True)

        # # read back in the config file, and only overwite that line.
        # with open(config_file, "r") as file:
        #     lines = file.readlines()
        # new_lines = []
        # for line in lines:
        #     if line.startswith(f"{overwrite_key}:"):
        #         new_lines.append(f"{overwrite_key}: {configuration[overwrite_key]}\n")
        #     else:
        #         new_lines.append(line)
        # with open(config_file, "w") as file:
        #     file.writelines(new_lines)

    def write_back_configuration(self, configuration, config_file):
        # read back in the hostname file, if not set in this run, then the user can know the hostname after a first boot
        with open("/etc/hostname", "r") as file:
            current_name = file.readlines()[0].strip()
        # if XXXXX, then network setup did not set the hostname yet
        if current_name != "Mirte-XXXXXX":
            configuration["hostname"] = current_name
        self.overwrite_main_config(configuration, config_file, "hostname")

    def store_prev_config(self, configuration, prev_config_file):
        config_text = yaml.dump(configuration)
        with open(prev_config_file, "w") as file:
            file.writelines(config_text)

    def set_mirte_type(self, configuration):
        if "type" not in configuration:
            print("No mirte type specified, skipping")
            return
        mirte_type = configuration["type"]
        # type should be either mirte or mirte_master
        if mirte_type not in ["mirte", "mirte_master"]:
            print(
                f"Unknown Mirte type: {mirte_type}, should be either mirte or mirte_master"
            )
            return
        print(f"Setting Mirte type to {mirte_type}")
        # update ../services/mirte_ros_type.sh to set MIRTE_TYPE
        mirte_ros_type_file = os.path.join(
            os.path.dirname(os.path.realpath(__file__)), "../services/mirte_ros_type.sh"
        )
        with open(mirte_ros_type_file, "r") as file:
            lines = file.readlines()
        # if already set, then do not change it, otherwise change it
        for i, line in enumerate(lines):
            if line.startswith("export MIRTE_TYPE="):
                if line.strip() == f"export MIRTE_TYPE={mirte_type}":
                    print("Mirte type already set, skipping")
                    return
        with open(mirte_ros_type_file, "w") as file:
            file.write(f"export MIRTE_TYPE={mirte_type}\n")
        subprocess.run(["systemctl", "restart", "mirte-ros.service"], check=True)
        print("Mirte type set and service restarted")
