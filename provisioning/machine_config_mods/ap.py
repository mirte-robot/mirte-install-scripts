
import nmcli
import asyncio
import re

class machine_config_ap:
    
    def __init__(self, hostname, loop):
        self.hostname = hostname
        self.stop_signal = asyncio.Event()
        self.loop = loop
        self.hotspot_counter = 0
    
    def access_points(self, configuration):
        print(configuration)
        self.remove_aps(configuration)
        try:
            for ap in configuration["access_points"]:
                print(ap)
            self.loop.create_task(self.ap_loop(configuration))

        except Exception as e:
            print(e)

    def remove_aps(self, configuration):
        deletions = configuration.get("remove_access_points", [])
        print(f"Removing access points matching: {deletions}")
        if deletions is None or len(deletions) == 0:
            return
        # deletions is list of regexes to match ssids to remove
        connections = nmcli.connection()
        print(connections  )
        wifi_conns = list(
            filter(
                lambda conn: conn.conn_type == "wifi", connections
            )
        )
        for conn in wifi_conns:
            print(f"Checking connection {conn.name} for removal")
            for deletion in deletions:
                print(f"Checking if connection {conn.name} matches deletion regex {deletion}")
                if re.match(deletion, conn.name):
                    print(f"Deleting connection {conn.name} matching {deletion}")
                    nmcli.connection.delete(conn.uuid)
                    break

    async def stop(self):
        self.stopped = True


    # Nmcli can only connect to a network that is in the air, so we need to continuously check available networks and if not connected, try any known connections
    async def ap_loop(self, configuration):
        await self.check_ap(configuration) # timeout occurred, so we check access points
        while not self.stop_signal.is_set():
            try:
                await asyncio.wait_for(self.stop_signal.wait(), timeout=60.0) # sleep for 10 seconds, or until stop signal is set
            except asyncio.TimeoutError:
                await self.check_ap(configuration) # timeout occurred, so we check access points


    async def check_ap(self, configuration):
        connections = nmcli.connection()
        wifi_conn = list(
            filter(
                lambda conn: conn.conn_type == "wifi" and conn.device != "--", connections
            )
        )
        if len(wifi_conn) > 0:
            connection = wifi_conn[0]
            print(f"Connected to wifi network: {connection.name}")
            print(f"Current hostname: {self.hostname}")
            if connection.name != self.hostname:  # we have a connection to a wifi point
                print("existing wifi connection")
                self.hotspot_counter = 0
                return
        # No connection or own hotspot
        aps = nmcli.device.wifi()
        nmcli.device.wifi_rescan()  # rescan for wifi networks
        aps = list(map(lambda ap: ap.ssid, aps))
        print(f"Available access points: {aps}")
        print(f"Known access points: {configuration['access_points']}")

        # known_aps = list(map(lambda ap: ap.ssid, ))
        def known_ap_filter(known_ap):
            print(f"knownap {known_ap}")
            # known_ap = configuration["access_points"][known_ap]
            print(f"Checking if known ap {known_ap['ssid']} is in available aps and configuration access points")
            print(f"Available aps: {aps}")
            print(f"Known ap ssid: {known_ap['ssid']}")
            print(f"Is known ap ssid in available aps? {known_ap['ssid'] in aps}")
            return known_ap["ssid"] in aps
        existing_known_aps = list(
            filter(known_ap_filter, configuration["access_points"])
        )
        print(f"Existing known access points: {existing_known_aps}")
        # keep ordering of known aps
        if len(existing_known_aps) > 0:
            for((i, ap)) in enumerate(existing_known_aps):
                print(ap)
                print(f"Trying to connect to known ap {ap['ssid']} with password {ap['password']}")
                try:
                    out = nmcli.device.wifi_connect(ap["ssid"], ap["password"])
                    print("connected successfully")
                    self.hotspot_counter = 0
                    return
                except Exception as e:
                    print(f"Error connecting to {ap}: {e}")
                    print("Trying next known ap if available")
            # ap = existing_known_aps[0]
            # print(f"connecting to {ap}")
            # try:
            #     out = nmcli.device.wifi_connect(ap["ssid"], ap["password"])
            #     print("connected successfully")
            # except Exception as e:
            #     print(f"Error connecting to {ap}: {e}")
            self.hotspot_counter = 0
            return
        if "disable_hotspot" in configuration and configuration["disable_hotspot"]:
            print("Hotspot disabled")
            print("configuration: " + str(configuration))
            return
        print("No known access points available, if not found in 1m, start hotspot")
        self.hotspot_counter += 1
        if self.hotspot_counter >= 10:  # 30*2s = 1m
            print("Starting hotspot")
            # get password from /home/mirte/.wifi_password
            with open("/home/mirte/.wifi_pwd", "r") as file:
                password = file.read().strip()
            nmcli.device.wifi_hotspot(ifname=None,
                          con_name= None,
                          ssid=self.hostname,
                          band=None,
                          channel= None,
                          password= password)

            # nmcli.device.wifi_hotspot(self.hostname, password)
            self.hotspot_counter = 0

        
    
    def stop(self):
        self.stop_signal.set()