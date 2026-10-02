#!/usr/bin/python3
import json
import re
import subprocess
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from urllib.parse import urlsplit


def change_password(old_password, new_password):
    # using su is not possible as expired passwords will not allow su to work, so we use sudo passwd instead
    # THis'll ask for the old password, then the new password twice, and will return 0 on success

    try:
        result = subprocess.run(
            ["sudo", "-u", "mirte", "passwd"],
            input=f"{old_password}\n{new_password}\n{new_password}\n",
            text=True,
            stdout=subprocess.PIPE,
            stderr=subprocess.STDOUT,
            timeout=10,
            check=False,
        )
    except subprocess.TimeoutExpired:
        return {"ok": False, "msg": "Password change timed out."}
    if result.returncode != 0:
        if "Authentication token manipulation error" in result.stdout:
            return {"ok": False, "msg": "Old password is incorrect."}
        return {
            "ok": False,
            "msg": f"Password change failed: {result.stdout.strip()} (return code: {result.returncode})",
        }
    return {
        "ok": result.returncode == 0,
        "msg": f"Password change {'succeeded' if result.returncode == 0 else 'failed'}: {result.stdout.strip()} (return code: {result.returncode})",
    }


def parse_request(body):
    try:
        fields = json.loads(body)
        if not isinstance(fields, dict):
            raise ValueError
    except (ValueError, json.JSONDecodeError):
        return {"ok": False, "msg": "Invalid JSON request body."}

    old_password = str(fields.get("old_password") or "")
    new_password = str(fields.get("new_password") or "")

    if not old_password or not new_password:
        return {"ok": False, "msg": "Please fill in all fields."}
    if len(new_password) < 8:
        return {
            "ok": False,
            "msg": "New password must be at least 8 characters long.",
        }
    # escape old password to prevent injection
    escaped_old_password = re.escape(old_password)
    # escape new password to prevent injection
    escaped_new_password = re.escape(new_password)

    if escaped_old_password == escaped_new_password:
        return {
            "ok": False,
            "msg": "New password cannot be the same as the old password.",
        }

    if re.fullmatch(r"[a-zA-Z0-9_-]+", new_password) is None:
        return {
            "ok": False,
            "msg": "New password can only contain letters, numbers, - and _ .",
        }

    return change_password(escaped_old_password, escaped_new_password)


class PasswordChangeHandler(BaseHTTPRequestHandler):
    endpoint = "/password/change_password.py"
    max_content_length = 16_384

    def do_POST(self):
        if urlsplit(self.path).path != self.endpoint:
            self.send_error(404)
            return

        try:
            content_length = int(self.headers.get("Content-Length", "0"))
        except ValueError:
            self.send_error(400, "Invalid Content-Length")
            return

        if content_length < 0 or content_length > self.max_content_length:
            self.send_error(413, "Request body too large")
            return

        body = self.rfile.read(content_length).decode("utf-8", errors="replace")
        response = parse_request(body)
        response_body = json.dumps(response).encode("utf-8")
        self.send_response(200)
        self.send_header("Content-Type", "application/json; charset=utf-8")
        self.send_header("Content-Length", str(len(response_body)))
        self.end_headers()
        self.wfile.write(response_body)

    def log_message(self, format, *args):
        return


if __name__ == "__main__":
    ThreadingHTTPServer(("127.0.0.1", 8081), PasswordChangeHandler).serve_forever()
