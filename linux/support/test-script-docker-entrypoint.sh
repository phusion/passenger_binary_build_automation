#!/bin/bash
set -e
source /hbb/activate
source /system/shared/lib/library.sh

RUBY_VERSIONS=(`cat /system/shared/definitions/ruby_versions`)
LAST_RUBY_VERSION=${RUBY_VERSIONS[${#RUBY_VERSIONS[@]} - 1]}

/system/linux/support/inituidgid.sh

export PASSENGER_ROOT=/tmp/passenger
export PACKAGED_ARTEFACTS_DIR=/packaged
export UNPACKAGED_ARTEFACTS_DIR=/unpackaged

run setuser builder /system/shared/build/copy-passenger-source-dir.sh /passenger /tmp/passenger
run_exec setuser builder \
	/usr/local/rvm/bin/rvm-exec ruby-$LAST_RUBY_VERSION \
	rspec --tty -c -f d /system/shared/test/integration_test.rb "$@"
