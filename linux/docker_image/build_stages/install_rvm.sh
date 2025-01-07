#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate

header "Installing RVM"

KEYSERVERS=(
	keyserver.ubuntu.com
	hkp://keyserver.ubuntu.com:80
	hkp://pgp.mit.edu
	pgp.mit.edu
	hkp://keyserver.pgp.com
	hkp://keys.gnupg.net
	ha.pool.sks-keyservers.net
	hkp://p80.pool.sks-keyservers.net:80
	hkp://ipv4.pool.sks-keyservers.net
	-end-
)

KEYS=(
	409B6B1796C275462A1703113804BB82D39DC0E3
	7D2BAF1CF37B13E2069D6956105BD0E739499BDB
)

# We've had too many problems with keyservers. No matter which one we pick,
# it will fail some of the time for some people. So just try a whole bunch
# of them.
for KEY in "${KEYS[@]}"; do
	for KEYSERVER in "${KEYSERVERS[@]}"; do
		if [[ "$KEYSERVER" = -end- ]]; then
			echo 'ERROR: exhausted list of keyservers' >&2
			exit 1
		else
			echo "+ gpg --keyserver $KEYSERVER --recv-keys ${KEY}"
			gpg --keyserver "$KEYSERVER" --recv-keys "${KEY}" && break || echo 'Trying another keyserver...'
		fi
	done
done

run curl -L -o /tmp/install-rvm.sh https://get.rvm.io
run bash /tmp/install-rvm.sh master
run /usr/local/rvm/bin/rvm autolibs disable
