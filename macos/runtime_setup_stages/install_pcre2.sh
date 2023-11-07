#!/bin/bash
set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
source "$ROOTDIR/shared/lib/library.sh"

PCRE2_VERSION=$(cat "$ROOTDIR/shared/definitions/pcre2_version")

header "Installing PCRE2 $PCRE2_VERSION"
download_and_extract "pcre2-$PCRE2_VERSION.tar.gz" \
	"pcre2-$PCRE2_VERSION" \
	"https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$PCRE2_VERSION/pcre2-$PCRE2_VERSION.tar.gz"
echo "+ rm -f $WORKDIR/pcre2-$PCRE2_VERSION.tar.gz"
rm -f "$WORKDIR/pcre2-$PCRE2_VERSION.tar.gz"
echo "+ ./configure --prefix=$OUTPUT_DIR --enable-static --disable-shared CFLAGS='-O2 -fvisibility=hidden'"
./configure --prefix="$OUTPUT_DIR" --enable-static --disable-shared CFLAGS='-O2 -fvisibility=hidden'
echo "+ make -j$CONCURRENCY"
make -j"$CONCURRENCY"
echo "+ make install-strip"
make install-strip
