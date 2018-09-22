#!/bin/bash
set -e
set -o pipefail
source /hbb/activate
source /system/shared/lib/library.sh

# Note that we do not use gpg-agent inside Docker. The reason is as follows.
#
# GPG passes the current TTY's name to pinentry, and pinentry tries to
# read the password from that TTY. But Docker sets its environment up
# in such a way that the filename of the TTY's filename refers to a
# nonexistant file.
#
# It even looks like real TTYs don't exist inside a Docker container.
# Since pinentry is run from gpg-agent, and gpg-agent is daemonized,
# there is no way for pinentry to get a hold on the original TTY.
# The loopback mode works around this problem.
#
# I tried setting pinentry to loopback mode as described here...
# http://stackoverflow.com/questions/36356924/not-a-tty-error-in-alpine-based-duplicity-image
# ...but it didn't work. Why it didn't work is unknown: I stopped
# bothering investigating it further.

/system/linux/support/inituidgid.sh

export WORKDIR=`setuser builder mktemp -d /tmp/publish.XXXXXXXX`
export INPUT_DIR=/input
export FILE_SERVER_PASSWORD=`cat /file_server_password`
export AWS_SECRET_KEY=`cat /aws_secret_key`

setuser builder mkdir ~builder/.gnupg
setuser builder chmod 700 ~builder/.gnupg
setuser builder touch ~builder/.gnupg/gpg.conf

if [[ ! -e /signing_key_password ]]; then
	PASSWORD=`echo -e 'OPTION ttyname /dev/tty\nSETDESC Enter your GPG key password.\nSETPROMPT GPG key password:\nGETPIN' | pinentry-curses | grep ^D `
	echo "$PASSWORD" | sed 's/^D //' > /signing_key_password
	run cat /signing_key_password
fi

export GPG_OPTS='--batch --trust-model always --passphrase-file /signing_key_password'
export GPG_TTY=/dev/tty

echo "+ Importing GPG key"
setuser builder gpg --batch -q --import /signing_key

export GPG_SIGNING_KEY=`setuser builder gpg --list-secret-keys --keyid-format short | grep '^sec' | awk '{ print $2 }' | sed 's/.*\///' | head -n 1`
echo "+ Signing key ID: $GPG_SIGNING_KEY"

run_exec setuser builder /system/shared/publish/publish.sh
