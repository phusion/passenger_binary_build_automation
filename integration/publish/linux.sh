#!/bin/bash
# Usage: integration/publish/linux.sh
# This script is from the "Passenger binaries (release)" Jenkins job. It builds
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
#   env WORKSPACE=$HOME PASSENGER_ROOT=/passenger ./jenkins/test/test.sh

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
DOCKER_IMAGE_MAJOR_VERSION=$(cat "shared/definitions/docker_image_major_version")

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

run docker pull phusion/passenger_binary_build_automation_32:$DOCKER_IMAGE_MAJOR_VERSION
run docker pull phusion/passenger_binary_build_automation_64:$DOCKER_IMAGE_MAJOR_VERSION

run rm -rf "$WORKSPACE/output"/*
run mkdir -p "$WORKSPACE/cache/x86" "$WORKSPACE/output/x86" \
	"$WORKSPACE/cache/x86_64" "$WORKSPACE/output/x86_64"

echo
echo "---------- Building x86 binaries ----------"
run ./linux/build \
	-p "$PASSENGER_ROOT" \
	-c "$WORKSPACE/cache/x86" \
	-o "$WORKSPACE/output/x86" \
	-a x86 \
	-j "$CONCURRENCY" \
	passenger nginx

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
echo "---------- Testing x86 binaries ----------"
run ./linux/package \
	-i "$WORKSPACE/output/x86" \
	-o "$WORKSPACE/output/x86" \
	-a x86
run ./linux/test \
	-p "$PASSENGER_ROOT" \
	-i "$WORKSPACE/output/x86" \
	-I "$WORKSPACE/output/x86" \
	-a x86 \
	-L ~/passenger-enterprise-license

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

echo
echo "---------- Publishing x86 binaries ----------"
run ./linux/publish \
	-i "$WORKSPACE/output/x86" \
	-v "$PASSENGER_VERSION" \
	-S ~/auto-software-signing@phusion.nl.asc \
	-x ~/.auto-software-signing@phusion.nl.password \
	-p ~/.passenger_binary_build_automation_file_server_password \
	-a `cat ~/.passenger_binary_build_automation_s3_access_key` \
	-s ~/.passenger_binary_build_automation_s3_password \
	"${PUBLISH_ARGS[@]}"

echo
echo "---------- Publishing x86_64 binaries ----------"
run ./linux/publish \
	-i "$WORKSPACE/output/x86_64" \
	-v "$PASSENGER_VERSION" \
	-S ~/auto-software-signing@phusion.nl.asc \
	-x ~/.auto-software-signing@phusion.nl.password \
	-p ~/.passenger_binary_build_automation_file_server_password \
	-a `cat ~/.passenger_binary_build_automation_s3_access_key` \
	-s ~/.passenger_binary_build_automation_s3_password \
	"${PUBLISH_ARGS[@]}"
