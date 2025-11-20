import subprocess
import yaml
import os
from deepdiff import DeepDiff
import nmcli
import asyncio
import provisioning_module
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
            self.access_points(configuration, loop)
        if "password" in configuration:
            self.set_password(
                configuration["password"], prev_configuration["password"]
            )  # todo: do only when not already done
        self.install_system(configuration=configuration)
        self.set_mirte_type(configuration=configuration)
        # todo: if usb is installed with bootable and img, nuke first part of this disk and reboot
        self.write_back_configuration(configuration, config_file)
        self.store_prev_config(configuration, prev_config_file)


    def access_points(self, configuration, loop):
        print(configuration)
        try:
            for ap in configuration["access_points"]:
                print(ap)
            self.loop.create_task(self.ap_loop(configuration))

        except Exception as e:
            print(e)


    async def stop(self):
        self.stopped = True


    # Nmcli can only connect to a network that is in the air, so we need to continuously check available networks and if not connected, try any known connections
    async def ap_loop(self, configuration):
        while not self.stopped:
            await asyncio.sleep(10)
            await self.check_ap(configuration)


    async def check_ap(self, configuration):
        connections = nmcli.connection()
        wifi_conn = list(
            filter(
                lambda conn: conn.conn_type == "wifi" and conn.device != "--", connections
            )
        )
        if len(wifi_conn) > 0:
            connection = wifi_conn[0]
            if connection.name != self.hostname:  # we have a connection to a wifi point
                print("existing wifi connection")
                return
        # No connection or own hotspot
        aps = nmcli.device.wifi()
        aps = list(map(lambda ap: ap.ssid, aps))
        # known_aps = list(map(lambda ap: ap.ssid, ))
        existing_known_aps = list(
            filter(lambda known_ap: known_ap["ssid"] in aps, configuration["access_points"])
        )
        # keep ordering of known aps
        if len(existing_known_aps) > 0:
            ap = existing_known_aps[0]
            print(f"connecting to {ap}")
            nmcli.device.wifi_connect(ap["ssid"], ap["password"])


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
        config_text = yaml.dump(configuration)
        with open(config_file, "w") as file:
            file.writelines(config_text)


    def store_prev_config(self, configuration, prev_config_file):
        config_text = yaml.dump(configuration)
        with open(prev_config_file, "w") as file:
            file.writelines(config_text)

    def get_root_part(self):
        with open('/proc/mounts', 'r') as f:
            for line in f:
                if line.startswith('/dev/'):
                    parts = line.split(' ')
                    if parts[1] == '/':
                        return parts[0]
        return None

    def install_system(self, configuration):
        # For installing the current os to emmc/nvme/sdcard
        if "install" not in configuration:
            print("No install configuration, skipping")
            return
        install_cfg = configuration["install"] # emmc, sd, emmc_os_only

        # current installation type
        current_install_part = self.get_root_part()
        remove_overlay = configuration.get("remove_overlay_partition", True)
        remove_settings = configuration.get("remove_settings_partition", True)
        # determine current installation type
        # eMMC installation has /dev/mmcblk0 as root device
        if current_install_part is None:
            print("Could not determine current root device, skipping installation")
            return
        if current_install_part.startswith('/dev/mmcblk0'):
            current_install = 'emmc'
        elif current_install_part.startswith('/dev/mmcblk1'):
            current_install = 'sd'
        elif current_install_part.startswith('/dev/nvme'):
            current_install = 'nvme'
        else:
            print(f"Unknown current root device: {current_install_part}, skipping installation")
            return
        
        print(f"Current installation type: {current_install}, requested: {install_cfg}")
        if current_install == install_cfg:
            print("Already installed to requested device, no action needed")
            return
        if install_cfg == "emmc":
            target_dev = "/dev/mmcblk0"
        elif install_cfg == "sd":
            target_dev = "/dev/mmcblk1"
            # Install to SD card
            pass
        elif install_cfg == "emmc_os_only":
            # target_dev
            # TODO: write only the OS partition to eMMC and update partition table accordingly
            # Install to eMMC, but only the OS
            pass
        elif install_cfg == "nvme":
            target_dev = "/dev/nvme0n1"
            # Install to NVMe
            pass

        if target_dev == "":
            print(f"Unknown target device for installation: {install_cfg}, skipping")
            return
        
        source_location = ""
        # if config has image_file, then use that file to install
        if "image_file" in configuration:
            image_file = configuration["image_file"]
            if not os.path.isfile(image_file):
                print(f"Image file {image_file} does not exist, skipping installation")
                return
            print(f"Installing image {image_file} to {target_dev}, this may take a while...")
            source_location = image_file
            # use dd to copy the image to the target device
            # subprocess.run(f"dd if={image_file} of={target_dev} bs=4M status=progress", shell=True, check=True)
            # print("Installation complete, please reboot the system to boot from the new device.")
            # return
        else :
            print(f"Installing system to {target_dev}, this may take a while...")
            # use dd to copy the current rootfs to the target device
            current_install_disk = subprocess.run(
                ["lsblk", "-no", "PKNAME", current_install_part],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            ).stdout.decode().strip()
            source_location = f"/dev/{current_install_disk}"
        print(f"Copying from {source_location} to {target_dev}")
        # stop all mirte services before copying
        for service in ["mirte-ros.service", "mirte-ap.service", "mirte-web-interface.service"]:
            try:
                subprocess.run(["systemctl", "stop", service], check=True)
            except subprocess.CalledProcessError:
                print(f"Failed to stop {service}, continuing...")
        if False:
            subprocess.run(f"dd if={source_location} of={target_dev} bs=4M status=progress", shell=True, check=True)
        # partprobe to inform kernel of partition table changes
        subprocess.run(["partprobe", target_dev], check=True)
        subprocess.run("sleep 2", shell=True, check=True)
        # TODO: after copying, update armbianenv on /boot/ to set uuid of rootfs to the new device
        # mount the target device boot partition
        boot_part = target_dev + "p1"
        mount_point = "/mnt/target_boot"
        os.makedirs(mount_point, exist_ok=True)
        print("Mounting target boot partition on " + mount_point + " to update rootfs uuid in armbianEnv.txt " + boot_part)
        out = subprocess.run(["mount", boot_part, mount_point], check=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE)
        if out.returncode != 0:
            print("Failed to mount target boot partition")
            print(out.stderr.decode().strip())
            return
        # read armbianenv file
        armbianenv_file = os.path.join(mount_point, "/boot/armbianEnv.txt")
        if not os.path.isfile(armbianenv_file):
            print("No armbianEnv.txt file found on target boot partition, cannot update rootfs uuid")
            subprocess.run(["umount", mount_point], check=True)
            return
        with open(armbianenv_file, "r") as file:
            lines = file.readlines()
        new_lines = []
        for line in lines:
            if line.startswith("rootdev_uuid="):
                # get uuid of target root partition
                target_root_part = target_dev + "p1"
                uuid = subprocess.run(
                    ["blkid", "-s", "UUID", "-o", "value", target_root_part],
                    check=True,
                    stdout=subprocess.PIPE,
                    stderr=subprocess.PIPE,
                ).stdout.decode().strip()
                print(f"Setting rootdev_uuid to {uuid}")
                line = f"rootdev_uuid={uuid}\n"
            new_lines.append(line)
        with open(armbianenv_file, "w") as file:
            file.writelines(new_lines)
        subprocess.run(
            # chroot to target device and run systemctl enable armbian-resize-filesystem.service
            ["chroot", f"{mount_point}", "systemctl", "enable", "armbian-resize-filesystem.service"],
        )
        subprocess.run(["umount", mount_point], check=True)
        # update partitions, remove existing partitions on target device except the first one (boot)
        # TODO: change it to remove MIRTE partition

        if remove_overlay:
            # get partition table, get partition named mirte_root
            print("Removing overlay partition")
            part_list = subprocess.run(
                "lsblk -o NAME,LABEL -nr {}".format(target_dev).split(),
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            ).stdout.decode().strip().split("\n")
            mirte_root_part_num = None
            for line in part_list:
                if "mirte_root" in line:
                    tokens = line.split()
                    mirte_root_part_num = tokens[0][-1]  # last character is partition number
                    break
            if mirte_root_part_num is None:
                print("No mirte_root partition found, cannot remove overlay partition")
                # return
            else:
                subprocess.run(["parted", target_dev, "rm", mirte_root_part_num], check=True)
        if remove_settings:
            print("Removing settings partition")
            part_list = subprocess.run(
                ["lsblk", "-o", "NAME,LABEL", "-nr", target_dev],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            ).stdout.decode().strip().split("\n")
            mirte_settings_part_num = None
            for line in part_list:
                if "MIRTE" in line :
                    tokens = line.split()
                    # mirte must be the only part of this name
                    for token in tokens:
                        if token.startswith("MIRTE") and token != "MIRTE":
                            continue 
                    mirte_settings_part_num = tokens[0][-1] # last character is partition number
                    break
            if mirte_settings_part_num is None:
                print("No MIRTE settings partition found, cannot remove settings partition")
                # return
            else:
                subprocess.run(["parted", target_dev, "rm", mirte_settings_part_num], check=True)
        # subprocess.run(["parted", target_dev, "rm", "3"], check=True)
        # create new partition table with rootfs partition taking the rest of the space
        
        print("Installation complete, please reboot the system to boot from the new device.")


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