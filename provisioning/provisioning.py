#!/usr/bin/python3
import time
import asyncio
import traceback
from signal import SIGINT, SIGTERM
import os

# Provisioning system for the Mirte sd cards.
# Only activate this service when you want to copy configurations from the second partition to the operating system

# assume mounting point is /mnt/mirte, otherwise change it here to somewhere to let the modules take out the required info
mount_point = "/mnt/mirte/"

import robot_config
import machine_config
import ssh
import mounter

module_types = [robot_config.RobotConfig, machine_config.MachineConfig, ssh.SSHConfig]
modules = []


async def stop(event_loop):
    for module in modules:
        try:
            await module.stop()
        except Exception as e:
            print(e)
    event_loop.stop()


if __name__ == "__main__":
    # test if started as root, if not, exit with error
    if not (os.geteuid() == 0):
        print("This script must be run as root, exiting.")
        exit(1)

    event_loop = asyncio.get_event_loop()
    mounted = True
    if not mounter.mount(mount_point):
        print("Could not mount extra partition, not provisioning configs")
        mounted = False
    for module in module_types:
        if module.needs_mount and not mounted:
            print(f"Skipping module {module} as mount is required but not available")
            continue
        modules.append(module(mount_point, event_loop))

    for module in modules:

        try:
            # if mounted or not module.needs_mount:
            module.start(mount_point, event_loop)
        except Exception as e:
            print(e)
            print(traceback.format_exc())
    for signal in [SIGINT, SIGTERM]:
        event_loop.add_signal_handler(
            signal, lambda: event_loop.create_task(stop(event_loop))
        )

    event_loop.run_forever()

    pending = asyncio.all_tasks(loop=event_loop)
    event_loop.run_until_complete(asyncio.gather(*pending))
    event_loop.close()
