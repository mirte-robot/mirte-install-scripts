
import nmcli
import asyncio


class machine_config_ap:
    
    def __init__(self, hostname, loop):
        self.hostname = hostname
        self.stop_signal = asyncio.Event()
        self.loop = loop
    
    def access_points(self, configuration):
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
        while not self.stop_signal.is_set():
            try:
                await asyncio.wait_for(self.stop_signal.wait(), timeout=10.0) # sleep for 10 seconds, or until stop signal is set
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
    
    def stop(self):
        self.stop_signal.set()