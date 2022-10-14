#!/bin/bash
# Usage: integration/test/test.sh
# This script is invoked from the "Passenger binaries test" Jenkins job. It builds
# portable binaries for Passenger and Nginx and runs tests against them.
#
# Required environment variables:
#
#   WORKSPACE
#   ENTERPRISE (true or false)
#
# Optional environment variables:
#
#   PASSENGER_ROOT (defaults to $WORKSPACE)
#   CONCURRENCY
#
# Sample invocation in a development environment:
#
#   env WORKSPACE=$HOME PASSENGER_ROOT=/passenger ./integration/test/test.sh

set -e
SELFDIR=`dirname "$0"`
cd "$SELFDIR/../.."
source "./shared/lib/library.sh"

require_envvar WORKSPACE "$WORKSPACE"
require_envvar ENTERPRISE "$ENTERPRISE"

PASSENGER_ROOT="${PASSENGER_ROOT:-$WORKSPACE}"
CONCURRENCY=${CONCURRENCY:-2}

if [[ ! -e ~/passenger-enterprise-license ]]; then
	echo "ERROR: ~/passenger-enterprise-license required."
	exit 1
fi

# Sleep for a random amount of time in order to work around Docker/AUFS bugs
# that may be triggered if multiple containers are shut down at the same time.
echo 'import random, time; time.sleep(random.random() * 4)' | python

run rm -rf "$WORKSPACE/output"

for ARCH in arm64 amd64; do
run mkdir -p "$WORKSPACE/cache/arm64" "$WORKSPACE/output/arm64"

echo
echo "---------- Building $ARCH binaries ----------"
run ./linux/build \
	-p "$PASSENGER_ROOT" \
	-c "$WORKSPACE/cache/$ARCH" \
	-o "$WORKSPACE/output/$ARCH" \
	-a "$ARCH" \
	-j "$CONCURRENCY" \
	passenger nginx

echo
echo "---------- Testing $ARCH binaries ----------"
run ./linux/package \
	-i "$WORKSPACE/output/$ARCH" \
	-o "$WORKSPACE/output/$ARCH" \
	-a "$ARCH"
run ./linux/test \
	-p "$PASSENGER_ROOT" \
	-i "$WORKSPACE/output/$ARCH" \
	-I "$WORKSPACE/output/$ARCH" \
	-a "$ARCH" \
	-L ~/passenger-enterprise-license
done
