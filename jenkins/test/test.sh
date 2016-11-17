#!/bin/bash
# Usage: test.sh
# This script is from the "Passenger binaries test" Jenkins job. It builds
# portable binaries for Passenger and Nginx and runs tests against them.
#
# Required environment variables:
#
#   WORKSPACE
#
# Optional environment variables:
#
#   PASSENGER_ROOT (defaults to $WORKSPACE)
#   CONCURRENCY
#
# Sample invocation in a development environment:
#
#   env WORKSPACE=$HOME PASSENGER_ROOT=/passenger ./jenkins/test/test.sh

set -e
SELFDIR=`dirname "$0"`
cd "$SELFDIR/../.."
source "./shared/lib/library.sh"

require_envvar WORKSPACE "$WORKSPACE"

PASSENGER_ROOT="${PASSENGER_ROOT:-$WORKSPACE}"
CONCURRENCY=${CONCURRENCY:-4}

# Sleep for a random amount of time in order to work around Docker/AUFS bugs
# that may be triggered if multiple containers are shut down at the same time.
echo 'import random, time; time.sleep(random.random() * 4)' | python

run mkdir -p cache output
run ./linux/build \
	-p "$PASSENGER_ROOT" \
	-c "$WORKSPACE/cache/x86" \
	-o "$WORKSPACE/output/x86" \
	-a x86 \
	passenger nginx
run ./linux/build \
	-p "$PASSENGER_ROOT" \
	-c "$WORKSPACE/cache/x86_64" \
	-o "$WORKSPACE/output/x86_64" \
	-a x86_64 \
	passenger nginx
