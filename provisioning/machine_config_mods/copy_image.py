

import os
import subprocess

import yaml



# Install OS to eMMC/NVMe/SD card based on configuration
# Not just copying the OS_partition, but the whole disk image or dd from current rootfs to target device
# then remove overlay and settings partitions if needed as uboot lives somewhere as well





def get_root_part():
    with open('/proc/mounts', 'r') as f:
        for line in f:
            if line.startswith('/dev/'):
                parts = line.split(' ')
                if parts[1] == '/':
                    return parts[0]
    return None

def install_system(configuration):
    # For installing the current os to emmc/nvme/sdcard
    if "install" not in configuration:
        print("No install configuration, skipping")
        return
    install_cfg = configuration["install"] # emmc, nvme,sd
    if(install_cfg not in ["emmc", "nvme", "sd"]):
        print(f"Unknown install configuration: {install_cfg}, skipping")
        return


    # current installation type
    current_install_part = get_root_part()
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
    elif install_cfg == "nvme":
        target_dev = "/dev/nvme0n1"
        # Install to NVMe
        pass

    if target_dev == "":
        print(f"Unknown target device for installation: {install_cfg}, skipping")
        return
   
        
    print(f"Installing system to {target_dev}, this may take a while...")
    # check if target device exists
    if not os.path.exists(target_dev):
        print(f"Target device {target_dev} does not exist, cannot install")
        return

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
    
    # TODO: get end of source, armbi_root as that's what we want to copy
    # size_to_copy = subprocess.run(
    #     f"parted {source_location} unit B print | grep armbi_root | awk '{{print $3}}' | sed 's/B//'",
    #     shell=True,
    #     check=True,
    #     stdout=subprocess.PIPE,
    #     stderr=subprocess.PIPE,
    # ).stdout.decode().strip()
    # print(f"Size to copy: {size_to_copy} bytes")

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
    
    # TODO: check if move is neede for armbian_root partition to begin of disk

    if configuration.get("remove_os_from_sd", False): # 'sd': install medium
        # remove armbi_root from source_location
        if current_install == "sd":
            print("Removing OS partitions from SD card")
            source_dev = source_location
            part_list = subprocess.run(
                ["lsblk", "-o", "NAME,LABEL", "-nr", source_dev],
                check=True,
                stdout=subprocess.PIPE,
                stderr=subprocess.PIPE,
            ).stdout.decode().strip().split("\n")
            armbian_root_part_num = None
            for line in part_list:
                if "armbi_root" in line:
                    tokens = line.split()
                    armbian_root_part_num = tokens[0][-1]  # last character is partition number
                    break
            if armbian_root_part_num is None:
                print("No armbi_root partition found on SD card, cannot remove OS partitions")
            else:
                # echo -e "resizepart\n1\nYes\n100%\nprint free\nquit" | sudo parted /dev/vda ---pretend-input-tty

                subprocess.run(["echo", "-e", f"rm\n{armbian_root_part_num}\nYes\nquit", "|", "parted", "---pretend-input-tty", source_dev ], check=True, shell=True)
                # run dd to nuke source partition
                subprocess.run(f"dd if=/dev/zero of={source_dev}p{armbian_root_part_num} bs=4M status=progress count=100", shell=True, check=True)
                print("Removed OS partitions from SD card")
                # TODO: next boot: move other partitions if needed
                subprocess.run("echo b >/proc/sysrq-trigger", shell=True, check=True)
        
    
    print("Installation complete, please reboot the system to boot from the new device.")
    # reboot system
    # subprocess.run(["reboot"], check=True)
