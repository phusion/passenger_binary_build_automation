#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

ZLIB_VERSION=$(cat "$ROOTDIR/shared/definitions/zlib_version")

header "Installing zlib $ZLIB_VERSION"
download_and_extract zlib-$ZLIB_VERSION.tar.gz \
	zlib-$ZLIB_VERSION \
	https://zlib.net/fossils/zlib-$ZLIB_VERSION.tar.gz
run rm -f "$WORKDIR/zlib-$ZLIB_VERSION.tar.gz"
run env CFLAGS='-O2 -fvisibility=hidden' ./configure --prefix="$OUTPUT_DIR" --static
run make -j$CONCURRENCY
run make install
run strip -S "$OUTPUT_DIR/lib/libz.a"
