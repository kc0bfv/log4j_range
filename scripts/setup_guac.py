#!/usr/bin/env python3

"""
Based on API reference at https://github.com/ridvanaltun/guacamole-rest-api-documentation
"""

import json
import urllib.parse
import urllib.request

def require_token(func):
    def wrapper(self, *args, **kwargs):
        if self.token is None:
            raise RuntimeError("Token not set!")
        return func(self, *args, **kwargs)
    return wrapper

class GuacConnection:
    def __init__(self, urlbase):
        self.urlbase = urlbase
        self.token = None
        self.dataSource = None

    def get_url(self, api_point, url_dict=None, add_token=True):
        if url_dict is None:
            url_dict = dict()
        cur_url = urllib.parse.urljoin(self.urlbase, api_point)
        cur_url = cur_url.format(dataSource = self.dataSource, **url_dict)
        if add_token:
            cur_url = urllib.parse.urljoin(cur_url, "?token={}".format(self.token))
        return cur_url

    def get_token(self, username, password):
        print("Getting login token for: {}".format(username))

        dest = self.get_url("/api/tokens", add_token=False)
        data = "username={}&password={}".format(username, password)
        req = urllib.request.Request(dest, data.encode("ascii"))
        with urllib.request.urlopen(req, timeout=5) as resp:
            output = resp.read()

        outvals = json.loads(output)

        self.token, self.dataSource = outvals["authToken"], outvals["dataSource"]

        return True

    @require_token
    def change_password(self, username, old_password, new_password):
        print("Changing password for: {}".format(username))

        api_point = "/api/session/data/{dataSource}/users/{username}/password"
        dest = self.get_url(api_point, {"username": username})
        headers = {"Content-Type": "application/json"}

        data_dict = {"oldPassword": old_password, "newPassword": new_password}
        data = json.dumps(data_dict)

        req = urllib.request.Request(dest, data.encode("ascii"), headers, method="PUT")
        with urllib.request.urlopen(req, timeout=5) as resp:
            output = resp.read()
        if output == b"":
            print("Password changed")
            return True
        else:
            raise RuntimeError("Returned: {}".format(output.decode("utf-8")))

    @require_token
    def add_user(self, username, password):
        print("Creating user: {}".format(username))

        api_point = "/api/session/data/{dataSource}/users"
        dest = self.get_url(api_point)
        headers = {"Content-Type": "application/json"}

        data_dict = {
            "username": username,
            "password": password,
            "attributes": {
                "disabled": "",
                "expired": "",
                "access-window-start": "",
                "access-window-end": "",
                "valid-from": "",
                "valid-until": "",
                "timezone": None,
                "guac-full-name": "",
                "guac-organization": "",
                "guac-organizational-role": ""
            }
        }
        data = json.dumps(data_dict)

        req = urllib.request.Request(dest, data.encode("ascii"), headers, method="POST")
        try:
            with urllib.request.urlopen(req, timeout=5) as resp:
                output = resp.read()
        except urllib.error.HTTPError as e:
            output = e.read().decode("utf-8")
            if e.code == 400 and "already exists" in output:
                print("User already exists, not created")
                return False
                
        output_str = output.decode("utf-8")
        if username in output_str:
            print("User created")
            return True
        else:
            raise RuntimeError("Returned: {}".format(output.decode("utf-8")))

if __name__ == "__main__":
    guac = GuacConnection("https://log4jrange.lee.mx")

    DOING_TESTING = False
    DOING_TESTING = True

    if DOING_TESTING:
        guac.get_token("guacadmin", "guac_admin_secret_password")
    else:
        guac.get_token("guacadmin", "guacadmin")
        guac.change_password("guacadmin", "guacadmin", "guac_admin_secret_password")

    guac.add_user("red_player", "red_player_secret_password")
