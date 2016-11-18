#!/bin/bash
set -e
set -o pipefail

if [[ "$APP_UID" -lt 1024 ]]; then
	if awk -F: '{ print $3 }' < /etc/passwd | grep -q "^${APP_UID}$"; then
		echo "ERROR: you can only run this script with a user whose UID is at least 1024, or whose UID does not already exist in the Docker container. Current UID: $APP_UID"
		exit 1
	fi
fi
if [[ "$APP_GID" -lt 1024 ]]; then
	if awk -F: '{ print $4 }' < /etc/passwd | grep -q "^${APP_GID}$"; then
		echo "ERROR: you can only run this script with a user whose GID is at least 1024, or whose GID does not already exist in the Docker container. Current GID: $APP_GID"
		exit 1
	fi
fi

chown -R "$APP_UID:$APP_GID" /home/builder
groupmod -g "$APP_GID" builder
usermod -u "$APP_UID" -g "$APP_GID" builder

# There's something strange with either Docker or the kernel, so that
# the 'builder' user cannot access its home directory even after a proper
# chown/chmod. We work around it like this.
mv /home/builder /home/builder2
cp -dpR /home/builder2 /home/builder
rm -rf /home/builder2

if [[ $# -gt 0 ]]; then
	exec "$@"
fi
