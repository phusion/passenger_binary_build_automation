#!/bin/bash
# Usage: integration/publish/linux.sh
# This script is invoked from the "Passenger binaries (release)" Jenkins job. It builds
# portable binaries for Passenger and Nginx, runs tests against them and publishes
# them to the binaries file server and to Amazon S3.
#
# Required environment variables:
#
#   WORKSPACE
#   ENTERPRISE (true or false)
#   TESTING (true or false)
#
# Optional environment variables:
#
#   PASSENGER_ROOT (defaults to $WORKSPACE)
#   CONCURRENCY
#
# Sample invocation in a development environment:
#
#   env WORKSPACE=$HOME PASSENGER_ROOT=/passenger ./integration/publish/linux.sh

set -e

ROOTDIR="`dirname \"$0\"`"
cd "$ROOTDIR/../.."
ROOTDIR="`pwd`"
source "./shared/lib/library.sh"

require_envvar WORKSPACE "$WORKSPACE"
require_envvar ENTERPRISE "$ENTERPRISE"
require_envvar TESTING "$TESTING"

export PASSENGER_ROOT="${PASSENGER_ROOT:-$WORKSPACE}"
CONCURRENCY=${CONCURRENCY:-2}

PUBLISH_ARGS=()
if $ENTERPRISE; then
	PUBLISH_ARGS+=(-E)
fi
if ! $TESTING; then
	PUBLISH_ARGS+=(-u)
fi

REQUIRED_FILES=(
	~/auto-software-signing@phusion.nl.asc
	~/.auto-software-signing@phusion.nl.password
	~/.passenger_binary_build_automation_file_server_password
	~/.passenger_binary_build_automation_s3_access_key
	~/.passenger_binary_build_automation_s3_password
	~/passenger-enterprise-license
)
for F in "${REQUIRED_FILES[@]}"; do
	if [[ ! -e $F ]]; then
		echo "ERROR: $F required."
		exit 1
	fi
done

echo "+ Determining Passenger version number"
PASSENGER_VERSION="`"$ROOTDIR/shared/publish/determine_version_number.sh"`"

run rm -rf "$WORKSPACE/output"

#for ARCH in arm64 x86_64; do
for ARCH in x86_64; do
run mkdir -p "$WORKSPACE/cache/$ARCH" "$WORKSPACE/output/$ARCH"

echo
echo "---------- Building $ARCH binaries ----------"
run ./linux/build \
	-p "$PASSENGER_ROOT" \
	-c "$WORKSPACE/cache/$ARCH" \
	-o "$WORKSPACE/output/$ARCH" \
	-a $ARCH \
	-j "$CONCURRENCY" \
	passenger nginx

echo
echo "---------- Testing $ARCH binaries ----------"
run ./linux/package \
	-i "$WORKSPACE/output/$ARCH" \
	-o "$WORKSPACE/output/$ARCH" \
	-a $ARCH
run ./linux/test \
	-p "$PASSENGER_ROOT" \
	-i "$WORKSPACE/output/$ARCH" \
	-I "$WORKSPACE/output/$ARCH" \
	-a $ARCH \
	-L ~/passenger-enterprise-license

echo
echo "---------- Publishing $ARCH binaries ----------"
run ./linux/publish \
	-i "$WORKSPACE/output/$ARCH" \
	-v "$PASSENGER_VERSION" \
	-S ~/auto-software-signing@phusion.nl.asc \
	-x ~/.auto-software-signing@phusion.nl.password \
	-p ~/.passenger_binary_build_automation_file_server_password \
	-a `cat ~/.passenger_binary_build_automation_s3_access_key` \
	-s ~/.passenger_binary_build_automation_s3_password \
	"${PUBLISH_ARGS[@]}"
done
