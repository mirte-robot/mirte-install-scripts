# This file is part of cloud-init. See LICENSE file for license information.
"""Example Module: Shows how to create a module"""

import logging
from cloudinit.cloud import Cloud
from cloudinit.config import Config
from cloudinit.config.schema import MetaSchema
from cloudinit.distros import ALL_DISTROS
from cloudinit.settings import PER_INSTANCE, PER_ALWAYS
import os
LOG = logging.getLogger(__name__)

CONFIG_DIR = "/media/MIRTE_SETTINGS/"


meta: MetaSchema = {
    "id": "cc_mirte",
    "distros": [ALL_DISTROS],
    "frequency": PER_ALWAYS,
    "activate_by_schema_keys": [
        "mirte" # just run always
        ],
} # type: ignore

import threading
import time

def thread2():
    print("thread2 running")
    while True:
        time.sleep(10)
        print("thread2 alive")

thread = None
def handle(
    name: str, cfg: Config, cloud: Cloud, args: list
) -> None:
    global thread
    # print(f"Hi from module {name}")
    # print(cfg)
    mirte_cfg = cfg.get("mirte", {})
    print(mirte_cfg)
    thread = threading.Thread(target=thread2)
    thread.start()
    # print(cloud.get_datasource())
    # print(cloud.get_data())
    print(args)
    LOG.error(f"Hi from module {name}")