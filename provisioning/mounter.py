

def mount(mount_point, wanted_label="MIRTE_SETTI"):
    import subprocess
    # list all partitions
    # list all unmounted partitions and get the labels
    parts = subprocess.run(
        ["lsblk", "-o", "NAME,LABEL,MOUNTPOINT", "-nr"],
        check=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
    )
    lines = parts.stdout.decode().strip().split("\n")
    part_to_mount = []
    mounted_part = None
    for line in lines:
        tokens = line.split()
        if len(tokens) < 2:
            continue
        name = tokens[0]
        label = tokens[1]
        mountpoint = tokens[2] if len(tokens) > 2 else ""
        print(f"Found partition /dev/{name} with label {label} mounted on {mountpoint}")
        if label == wanted_label and mountpoint == "":
            part_to_mount.append(name)
            # break
        if label == wanted_label and mountpoint != "":
            mounted_part = name
    if mounted_part is not None:
        print(f"{wanted_label} partition already mounted on /dev/{mounted_part}")
        return True
    if len(part_to_mount) == 0:
        print(f"No unmounted {wanted_label} partition found")
        return False
    if len(part_to_mount) > 1:
        print(f"Multiple unmounted {wanted_label} partitions found, picking by order of usb, sdcard, nvme, emmc")
        print("Found partitions:", part_to_mount)
        part_to_mount = sorted(part_to_mount, key=lambda p: (p.startswith("sd"), p.startswith("mmcblk1"), p.startswith("nvme"), p.startswith("mmcblk0")), reverse=True)
        print("Sorted partitions:", part_to_mount)
        print("Picking partition:", part_to_mount[0])
    # else:
    part_to_mount = part_to_mount[0]
    try:
        # mkdir mount point if not exists
        subprocess.run(
            ["mkdir", "-p", mount_point],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        subprocess.run(
            ["mount", f"/dev/{part_to_mount}", mount_point],
            check=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.PIPE,
        )
        print(f"Mounted /dev/{part_to_mount} to {mount_point}")
        return True
    except subprocess.CalledProcessError as e:
        print(f"Failed to mount /dev/{part_to_mount}: {e.stderr.decode().strip()}")
        return False