class ProvisionModule:
    def __init__(self, mount_point=None, loop=None):
        self.mount_point = mount_point
        self.loop = loop

    def start(mount_point, loop):
        pass

    async def stop(self):
        print("stop provision module", self)
        pass

    needs_mount = False
