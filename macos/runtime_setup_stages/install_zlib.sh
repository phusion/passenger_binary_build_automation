#!/bin/bash
set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
source "$ROOTDIR/shared/lib/library.sh"

ZLIB_VERSION=$(cat "$ROOTDIR/shared/definitions/zlib_version")

header "Installing zlib $ZLIB_VERSION"
download_and_extract "zlib-$ZLIB_VERSION.tar.gz" \
	"zlib-$ZLIB_VERSION" \
	"https://zlib.net/fossils/zlib-$ZLIB_VERSION.tar.gz"
echo "+ rm -f $WORKDIR/zlib-$ZLIB_VERSION.tar.gz"
rm -f "$WORKDIR/zlib-$ZLIB_VERSION.tar.gz"
echo "+ env CFLAGS='-O2 -fvisibility=hidden' ./configure --prefix=$OUTPUT_DIR --static"
env CFLAGS='-O2 -fvisibility=hidden' ./configure --prefix="$OUTPUT_DIR" --static
echo "+ make -j$CONCURRENCY"
make -j"$CONCURRENCY"
echo "+ make install"
make install
echo "+ strip -S $OUTPUT_DIR/lib/libz.a"
strip -S "$OUTPUT_DIR/lib/libz.a"
