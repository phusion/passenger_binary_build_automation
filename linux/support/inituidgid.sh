#!/bin/bash
set -e

chown -R "$APP_UID:$APP_GID" /home/builder
groupmod -g "$APP_GID" builder
usermod -u "$APP_UID" -g "$APP_GID" builder

# There's something strange with either Docker or the kernel, so that
# the 'builder' user cannot access its home directory even after a proper
# chown/chmod. We work around it like this.
find ~builder -print0 | xargs -0 touch

if [[ $# -gt 0 ]]; then
	exec "$@"
fi
