import subprocess
import yaml
import os
from deepdiff import DeepDiff
import nmcli
import asyncio
import provisioning_module
from machine_config_mods import ap as machine_config_ap
from machine_config_mods import copy_image as machine_config_copy_image
needs_mount = True



prev_config_file = os.path.join(
    os.path.dirname(os.path.realpath(__file__)), "store/machine_config.yaml"
)
print(prev_config_file)

class MachineConfig(provisioning_module.ProvisionModule):
     
    needs_mount = True
    hostname = "Mirte-XXXXX"

    def start(self, mount_point, loop):
        self.stopped = False
        config_file = f"{mount_point}/machine_config.yaml"
        if not os.path.isfile(config_file):
            print("No machine_config configuration, stopping config provisioning")
            self.write_back_configuration({}, config_file)
            return

        with open(config_file, "r") as file:
            configuration = yaml.safe_load(file)
        with open(prev_config_file, "r") as file:
            prev_configuration = yaml.safe_load(
                file
            )  # this file should have all the configuration options
        configuration = {**prev_configuration, **configuration}
        if "hostname" in configuration:
            self.set_hostname(configuration["hostname"], prev_configuration["hostname"])
        if "access_points" in configuration:
            self.ap_config = machine_config_ap.machine_config_ap(
                self.hostname, loop
            )
            self.ap_config.access_points(configuration)
        if "password" in configuration:
            self.set_password(
                configuration["password"], prev_configuration["password"]
            )  # todo: do only when not already done
        machine_config_copy_image.install_system(configuration=configuration)
        self.set_mirte_type(configuration=configuration)
        # todo: if usb is installed with bootable and img, nuke first part of this disk and reboot
        self.write_back_configuration(configuration, config_file)
        self.store_prev_config(configuration, prev_config_file)

    def stop(self):
        if hasattr(self, 'ap_config'):
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
        with open("/etc/hostname", "w") as file:
            file.writelines(f"{new_hostname}\n")
            self.hostname = new_hostname


    def set_password(self, new_password, prev_set_password):
        if new_password == prev_set_password:
            # No need to update it and possibly the user edited it already by using the passwd command
            return
        if (
            len(new_password) < 8
        ):  # when changing as the mirte user, there are some checks, when changing as root, no checks
            return
        print(f'Changing password to "{new_password}"')
        o = os.system(f'sudo chpasswd mirte:{new_password}')
        print(o)


    def write_back_configuration(self, configuration, config_file):
        # read back in the hostname file, if not set in this run, then the user can know the hostname after a first boot
        with open("/etc/hostname", "r") as file:
            current_name = file.readlines()[0].strip()
        # if XXXXX, then network setup did not set the hostname yet
        if current_name != "Mirte-XXXXXX":
            configuration["hostname"] = current_name
        config_text = yaml.dump(configuration) # convert back to yaml, this will remove any comments
        with open(config_file, "w") as file:
            file.writelines(config_text)


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
            print(f"Unknown Mirte type: {mirte_type}, should be either mirte or mirte_master")
            return
        print(f"Setting Mirte type to {mirte_type}")
        # open mirte-ros service file and set the type
        service_file = "/etc/systemd/system/mirte-ros.service"
        if not os.path.isfile(service_file):
            print("No mirte-ros service file found, cannot set type")
            return
        # replace ExecStart=/usr/local/src/mirte/mirte-install-scripts/services/mirte_ros.sh <type> with new type
        with open(service_file, "r") as file:
            lines = file.readlines()
        new_lines = []
        for line in lines:
            if line.startswith("ExecStart="):
                if(line.endswith(f" {mirte_type}\n")):
                    print("Mirte type already correctly set in service file")
                    return
                print("Updating mirte type in service file" + line.strip())
                parts = line.strip().split(" ")
                if parts[-1] == mirte_type:
                    print("Mirte type already correctly set in service file")
                    return
                if parts[-1] not in ["mirte", "mirte_master"]:
                    print("Unknown mirte type in service file, overwriting")
                    parts.append(mirte_type)
                else:
                    parts[-1] = mirte_type
                line = " ".join(parts) + "\n"
                print("New line: " + line.strip())
            new_lines.append(line)
        with open(service_file, "w") as file:
            file.writelines(new_lines)
        # reload systemd daemon
        subprocess.run(["systemctl", "daemon-reload"], check=True)
        subprocess.run(["systemctl", "restart", "mirte-ros.service"], check=True)