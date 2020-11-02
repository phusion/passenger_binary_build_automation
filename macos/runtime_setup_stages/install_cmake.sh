#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

# the macos/support/bin/c++ script incorrectly uses cc instead of c++ here
export CXX=/usr/bin/c++

CMAKE_VERSION=$(cat "$ROOTDIR/shared/definitions/cmake_version")

header "Installing cmake $CMAKE_VERSION"
download_and_extract cmake-$CMAKE_VERSION.tar.gz \
	cmake-$CMAKE_VERSION \
	https://github.com/Kitware/CMake/releases/download/v${CMAKE_VERSION}/cmake-${CMAKE_VERSION}.tar.gz
run rm -f "$WORKDIR/cmake-$CMAKE_VERSION.tar.gz"
run ./bootstrap --prefix="$OUTPUT_DIR" --parallel=$CONCURRENCY || (cat Bootstrap.cmk/cmake_bootstrap.log && false)
run make -j$CONCURRENCY
run make install
run strip "$OUTPUT_DIR/bin/cmake"
