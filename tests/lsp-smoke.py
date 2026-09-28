"""Exercise the public `moon lsp` entry point over stdio."""

import json
import os
from pathlib import Path
import subprocess
import sys
import tempfile


def send(stream, message):
    payload = json.dumps(message, separators=(",", ":")).encode()
    stream.write(f"Content-Length: {len(payload)}\r\n\r\n".encode() + payload)
    stream.flush()


def receive(stream):
    length = None
    while True:
        line = stream.readline()
        if line in (b"\r\n", b"\n"):
            break
        if not line:
            raise RuntimeError("language server closed before responding")
        if line.lower().startswith(b"content-length:"):
            length = int(line.split(b":", 1)[1])
    if length is None:
        raise RuntimeError("language server response omitted Content-Length")
    return json.loads(stream.read(length))


moon = Path(sys.argv[1])
with tempfile.TemporaryDirectory() as temporary:
    environment = os.environ.copy()
    environment["HOME"] = temporary
    environment.pop("MOON_HOME", None)
    environment.pop("MOON_TOOLCHAIN_ROOT", None)
    # Deliberately omit the toolchain directory. The moon wrapper must provide
    # helper discovery for `nix run` and other direct store-path invocations.
    environment["PATH"] = "/usr/bin:/bin"
    server = subprocess.Popen(
        [moon, "lsp", "--stdio"],
        stdin=subprocess.PIPE,
        stdout=subprocess.PIPE,
        stderr=subprocess.PIPE,
        env=environment,
    )
    try:
        send(
            server.stdin,
            {
                "jsonrpc": "2.0",
                "id": 1,
                "method": "initialize",
                "params": {
                    "processId": None,
                    "rootUri": None,
                    "capabilities": {},
                },
            },
        )
        response = receive(server.stdout)
        if response.get("id") != 1 or "result" not in response:
            raise RuntimeError(f"unexpected initialize response: {response}")
        send(server.stdin, {"jsonrpc": "2.0", "id": 2, "method": "shutdown"})
        response = receive(server.stdout)
        if response.get("id") != 2 or "error" in response:
            raise RuntimeError(f"unexpected shutdown response: {response}")
        send(server.stdin, {"jsonrpc": "2.0", "method": "exit"})
        if server.wait(timeout=10) != 0:
            raise RuntimeError(server.stderr.read().decode())
    finally:
        if server.poll() is None:
            server.terminate()
            server.wait(timeout=5)
