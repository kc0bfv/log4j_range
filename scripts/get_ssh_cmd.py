#!/usr/bin/env python3

import json
import sys
import subprocess

if __name__ == "__main__":
    if len(sys.argv) != 2:
        print("Specify the host")
        exit(1)

    host = sys.argv[1]

    host_info_j = subprocess.check_output(["ansible-inventory", "--host", host])
    host_info = json.loads(host_info_j)

    if "ansible_host" not in host_info:
        # No host address found - using hostname
        host_info["ansible_host"] = host
    elif "ansible_user" not in host_info:
        print("No user address found")
        exit(1)

    ssh_key = ""
    if "ansible_ssh_private_key_file" in host_info:
        ssh_key = "-i {}".format(host_info["ansible_ssh_private_key_file"])

    ssh_cmd = [
        "ssh",
        "{}@{}".format(host_info["ansible_user"], host_info["ansible_host"]),
        "{}".format(host_info.get("ansible_ssh_common_args", "")),
        "{}".format(ssh_key),
    ]

    print(" ".join(ssh_cmd))
