import subprocess

def cleanup_overlayfs(config):
    if(not config.get("cleanup_overlay", False)):
        return

    try:
        print("Cleaning up overlay filesystem...")
        subprocess.run(["sudo", "rm", "-rf", "/media/root-rw/*"], check=True)
        # subprocess.run(["sudo", "umount", "/overlay"], check=True)

        print("Overlay filesystem cleaned up successfully.")
        # reboot the system
        print("Rebooting the system to apply changes...")
        subprocess.run(["sudo", "reboot", "now"], check=True)
    except subprocess.CalledProcessError as e:
        print(f"Failed to clean up overlay filesystem: {e.stderr.decode().strip()}")