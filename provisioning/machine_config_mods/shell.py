
import subprocess

import nmcli
import re

def set_shell(configuration):
    if "shell" not in configuration:
        return
    shell = configuration["shell"]
    if shell not in ["bash", "zsh"]:
        print(f"Invalid shell {shell} specified, ignoring")
        return
    print(f"Setting default shell to {shell}")
    # get current shell
    out = subprocess.run(["getent", "passwd", "mirte"], check=True, capture_output=True)
    current_shell = out.stdout.decode().strip().split(":")[-1]
    if current_shell.endswith(shell):
        print(f"Shell is already set to {shell}, skipping")
        return
    # figure out where shell is located
    out = subprocess.run(["which", shell], check=True, capture_output=True)
    print(out.stdout.decode())
    shell_path = out.stdout.decode().strip()
    if shell_path == "":
        print(f"Shell {shell} not found, skipping")
        return
    out =subprocess.run(["chsh", "-s", f"{shell_path}", "mirte"], check=True, capture_output=True)
    print(out.stdout.decode())