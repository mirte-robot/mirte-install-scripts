import subprocess


def cleanup_overlayfs(config, overwrite_main_config):
    if not config.get("cleanup_overlay", False):
        return

    try:
        # write back to the configuration that overlay has been cleaned
        config["cleanup_overlay"] = False
        overwrite_main_config(config, "cleanup_overlay")
        print("Cleaning up overlay filesystem...")
        out = subprocess.run("rm -rf /media/root-rw/*", check=True, shell=True)
        print(out)
        # subprocess.run(["sudo", "umount", "/overlay"], check=True)

        print("Overlay filesystem cleaned up successfully.")
        # reboot the system
        print("Rebooting the system to apply changes...")
        # echo b > /proc/sysrq-trigger
        out = subprocess.run(["sync"], check=True, shell=True)
        print(out)
        out = subprocess.run(["echo b > /proc/sysrq-trigger"], check=True, shell=True)
        print(out)
        # subprocess.run(["sudo", "reboot", "now"], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Failed to clean up overlay filesystem: {e}")
