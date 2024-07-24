#!/bin/bash
set -e
set -o pipefail
source /hbb/activate
source /system/shared/lib/library.sh

/system/linux/support/inituidgid.sh

export WORKDIR=`setuser builder mktemp -d /tmp/publish.XXXXXXXX`
export INPUT_DIR=/input
export FILE_SERVER_PASSWORD=`cat /file_server_password`
export AWS_SECRET_KEY=`cat /aws_secret_key`

setuser builder mkdir ~builder/.gnupg
setuser builder chmod 700 ~builder/.gnupg
setuser builder touch ~builder/.gnupg/gpg.conf
setuser builder touch ~builder/.gnupg/gpg-agent.conf

if [[ ! -e /signing_key_password ]]; then
	PASSWORD=`echo -e 'OPTION ttyname /dev/tty\nSETDESC Enter your GPG key password.\nSETPROMPT GPG key password:\nGETPIN' | pinentry-curses | grep ^D `
	echo "$PASSWORD" | sed 's/^D //' > /signing_key_password
	run cat /signing_key_password
fi

export GPG_OPTS="--batch --trust-model always --passphrase-file /signing_key_password"

echo "+ Ensuring GPG works in a non-TTY environment"
echo "use-agent" >> ~builder/.gnupg/gpg.conf
echo "no-tty" >> ~builder/.gnupg/gpg.conf
echo "pinentry-mode loopback" >> ~builder/.gnupg/gpg.conf
echo "pinentry-program /usr/bin/pinentry" >> ~builder/.gnupg/gpg-agent.conf
echo "allow-loopback-pinentry" >> ~builder/.gnupg/gpg-agent.conf

echo "+ Importing GPG key"
setuser builder gpg --batch -q --import /signing_key

export GPG_SIGNING_KEY=`setuser builder gpg --list-secret-keys --keyid-format short | grep '^sec' | awk '{ print $2 }' | sed 's/.*\///' | head -n 1`
echo "+ Signing key ID: $GPG_SIGNING_KEY"

run_exec setuser builder /system/shared/publish/publish.sh
