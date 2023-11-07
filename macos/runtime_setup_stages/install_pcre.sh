#!/bin/bash
set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
source "$ROOTDIR/shared/lib/library.sh"

PCRE_VERSION=$(cat "$ROOTDIR/shared/definitions/pcre_version")

header "Installing PCRE $PCRE_VERSION"
download_and_extract "pcre-$PCRE_VERSION.tar.gz" \
	"pcre-$PCRE_VERSION" \
	"https://sourceforge.net/projects/pcre/files/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz/download"
echo "+ rm -f $WORKDIR/pcre-$PCRE_VERSION.tar.gz"
rm -f "$WORKDIR/pcre-$PCRE_VERSION.tar.gz"
echo "+ ./configure --prefix=$OUTPUT_DIR --enable-static --disable-shared CFLAGS='-O2 -fvisibility=hidden'"
./configure --prefix="$OUTPUT_DIR" --enable-static --disable-shared CFLAGS='-O2 -fvisibility=hidden'
echo "+ make -j$CONCURRENCY"
make -j"$CONCURRENCY"
echo "+ make install-strip"
make install-strip
