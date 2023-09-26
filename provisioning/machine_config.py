import yaml
import os
from deepdiff import DeepDiff
import nmcli
import asyncio

prev_config = os.path.join( os.path.dirname(os.path.realpath(__file__)), "store/machine_config.yaml")
print(prev_config)

hostname = "Mirte-4A01A5"

def start(mount_point, loop):
    config_file = f"{mount_point}/machine_config.yaml"
    with open(config_file, 'r') as file:
        configuration = yaml.safe_load(file)
    with open(prev_config, 'r') as file:
        prev_configuration = yaml.safe_load(file)
    access_points(configuration, loop)
    

def access_points(configuration, loop):
    print(configuration)
    try:
        for ap in configuration["access_points"]:
            print(ap)
        loop.create_task(ap_loop(configuration))

    except Exception as e:
        print(e)

stopped = False
def stop():
    global stopped 
    stopped = True


async def ap_loop(configuration):
    while(not stopped):
        await asyncio.sleep(1)
        await check_ap(configuration)

async def check_ap(configuration):
    connections = nmcli.connection()
    wifi_conn = list(filter(lambda conn: conn.conn_type=='wifi' and conn.device!='--', connections))
    if(len(wifi_conn)>0):
        connection = wifi_conn[0]
        if(connection.name != hostname): # we have a connection to a wifi point
            print("existing wifi connection")
            return
    # No connection or own hotspot
    aps = nmcli.device.wifi()
    aps = list(map(lambda ap: ap.ssid, aps))
    # known_aps = list(map(lambda ap: ap.ssid, ))
    existing_known_aps = list(filter(lambda known_ap: known_ap["ssid"] in aps, configuration["access_points"]))
    # keep ordering of known aps
    if(len(existing_known_aps) > 0):
        ap = existing_known_aps[0]
        print(f"connecting to {ap}")
        nmcli.device.wifi_connect(ap["ssid"], ap["password"])
