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

run rm -rf "$WORKSPACE/output"/*
run mkdir -p "$WORKSPACE/cache/x86_64" "$WORKSPACE/output/x86_64"

echo
echo "---------- Building x86_64 binaries ----------"
run ./linux/build \
	-p "$PASSENGER_ROOT" \
	-c "$WORKSPACE/cache/x86_64" \
	-o "$WORKSPACE/output/x86_64" \
	-a x86_64 \
	-j "$CONCURRENCY" \
	passenger nginx

echo
echo "---------- Testing x86_64 binaries ----------"
run ./linux/package \
	-i "$WORKSPACE/output/x86_64" \
	-o "$WORKSPACE/output/x86_64" \
	-a x86_64
run ./linux/test \
	-p "$PASSENGER_ROOT" \
	-i "$WORKSPACE/output/x86_64" \
	-I "$WORKSPACE/output/x86_64" \
	-a x86_64 \
	-L ~/passenger-enterprise-license
