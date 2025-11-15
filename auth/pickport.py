#!/usr/bin/python3
# SPDX-License-Identifier: GPL-3.0-or-later

import socket

sock = socket.create_server(('', 0))
port = sock.getsockname()[1]

print(port)
