#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

# the macos/support/bin/c++ script incorrectly uses cc instead of c++ here
export CXX=/usr/bin/c++

CCACHE_VERSION=$(cat "$ROOTDIR/shared/definitions/ccache_version")

header "Installing ccache $CCACHE_VERSION"
download_and_extract ccache-$CCACHE_VERSION.tar.gz \
	ccache-$CCACHE_VERSION \
	https://github.com/ccache/ccache/releases/download/v${CCACHE_VERSION}/ccache-${CCACHE_VERSION}.tar.gz
run rm -f "$WORKDIR/ccache-$CCACHE_VERSION.tar.gz"
export MACOSX_DEPLOYMENT_TARGET=10.15
run cmake -DREDIS_STORAGE_BACKEND=OFF -DCMAKE_INSTALL_PREFIX="$OUTPUT_DIR" -S . -B build
run cmake --build build
run cmake --install build
run strip "$OUTPUT_DIR/bin/ccache"
