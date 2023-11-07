#!/bin/bash
# Usage: integration/publish/mac.sh
# This script is invoked from the "Passenger binaries (release)" Jenkins job. It builds
# portable binaries for Passenger and Nginx, runs tests against them and publishes
# them to the binaries file server and to Amazon S3.
#
# Required environment variables:
#
#   ENTERPRISE (true or false)
#   TESTING (true or false)
#
# Optional environment variables:
#
#   PASSENGER_ROOT (default: automatically inferred from Git submodule)
#   CONCURRENCY
#
# Sample invocation in a development environment:
#
#   env PASSENGER_ROOT=/path-to-passenger ./jenkins/linux/macos.sh

set -e

ROOTDIR="$(dirname "$0")"
cd "$ROOTDIR/../.."
ROOTDIR="$(pwd)"
source "./shared/lib/library.sh"

require_envvar ENTERPRISE "$ENTERPRISE"
require_envvar TESTING "$TESTING"

if [[ "$PASSENGER_ROOT" = "" ]]; then
	PASSENGER_ROOT="$(cd "$ROOTDIR" && pwd)"
	export PASSENGER_ROOT
	if [[ ! -e "$PASSENGER_ROOT/Rakefile" ]]; then
		echo "ERROR: passenger_binary_build_automation is not located inside a Passenger Git submodule"
		exit 1
	fi
else
	if [[ ! -e "$PASSENGER_ROOT/Rakefile" ]]; then
		echo "ERROR: PASSENGER_ROOT does not refer to a valid Passenger source root directory"
		exit 1
	fi
fi

WORKDIR="$PASSENGER_ROOT/buildout/binary_build_automation"
RUNTIME_DIR=~/.passenger_binary_build_automation/runtime
CACHE_DIR=~/.passenger_binary_build_automation/cache

CONCURRENCY=${CONCURRENCY:-2}

PUBLISH_ARGS=()
if $ENTERPRISE; then
	PUBLISH_ARGS+=(-E)
fi
if ! $TESTING; then
	PUBLISH_ARGS+=(-u)
fi

REQUIRED_FILES=(
	~/.passenger_binary_build_automation_file_server_password
	~/.passenger_binary_build_automation_s3_access_key
	~/.passenger_binary_build_automation_s3_password
	/etc/passenger-enterprise-license
)
for F in "${REQUIRED_FILES[@]}"; do
	if [[ ! -e $F ]]; then
		echo "ERROR: $F required."
		exit 1
	fi
done

echo "+ Determining Passenger version number"
PASSENGER_VERSION="$("$ROOTDIR/shared/publish/determine_version_number.sh")"

echo "+ rm -rf $WORKDIR"
rm -rf "$WORKDIR"
echo "+ mkdir -p $WORKDIR $WORKDIR/output $CACHE_DIR $RUNTIME_DIR"
mkdir -p "$WORKDIR" "$WORKDIR/output" "$CACHE_DIR" "$RUNTIME_DIR"

echo
echo "---------- Building runtime ----------"
echo "+ ./macos/setup-runtime -c $CACHE_DIR -o $RUNTIME_DIR -j $CONCURRENCY"
./macos/setup-runtime \
	-c "$CACHE_DIR" \
	-o "$RUNTIME_DIR" \
	-j "$CONCURRENCY"

echo
echo "---------- Building binaries ----------"
echo "+ ./macos/build -p $PASSENGER_ROOT -r $RUNTIME_DIR -c $CACHE_DIR -o $WORKDIR/output -j $CONCURRENCY passenger nginx"
./macos/build \
	-p "$PASSENGER_ROOT" \
	-r "$RUNTIME_DIR" \
	-c "$CACHE_DIR" \
	-o "$WORKDIR/output" \
	-j "$CONCURRENCY" \
	passenger nginx

echo
echo "---------- Testing binaries ----------"
echo "+ ./macos/package -i $WORKDIR/output -o $WORKDIR/output"
./macos/package \
	-i "$WORKDIR/output" \
	-o "$WORKDIR/output"
echo "+ ./macos/test -p $PASSENGER_ROOT -r $RUNTIME_DIR -i $WORKDIR/output -I $WORKDIR/output"
./macos/test \
	-p "$PASSENGER_ROOT" \
	-r "$RUNTIME_DIR" \
	-i "$WORKDIR/output" \
	-I "$WORKDIR/output"

echo
echo "---------- Publishing binaries ----------"
echo "+ ./macos/publish -r $RUNTIME_DIR -i $WORKDIR/output -v $PASSENGER_VERSION -p ~/.passenger_binary_build_automation_file_server_password -a $(cat ~/.passenger_binary_build_automation_s3_access_key) -s ~/.passenger_binary_build_automation_s3_password ${PUBLISH_ARGS[*]}"
./macos/publish \
	-r "$RUNTIME_DIR" \
	-i "$WORKDIR/output" \
	-v "$PASSENGER_VERSION" \
	-p ~/.passenger_binary_build_automation_file_server_password \
	-a "$(cat ~/.passenger_binary_build_automation_s3_access_key)" \
	-s ~/.passenger_binary_build_automation_s3_password \
	"${PUBLISH_ARGS[@]}"
