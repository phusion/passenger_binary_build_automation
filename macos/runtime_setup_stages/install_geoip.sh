#!/bin/bash
set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
source "$ROOTDIR/shared/lib/library.sh"

GEOIP_VERSION=$(cat "$ROOTDIR/shared/definitions/geoip_version")

header "Installing libcurl $GEOIP_VERSION"
download_and_extract "GeoIP-$GEOIP_VERSION.tar.gz" \
	"GeoIP-$GEOIP_VERSION" \
	"https://github.com/maxmind/geoip-api-c/releases/download/v$GEOIP_VERSION/GeoIP-$GEOIP_VERSION.tar.gz"
echo "+ rm -f $WORKDIR/GeoIP-$GEOIP_VERSION.tar.gz"
rm -f "$WORKDIR/GeoIP-$GEOIP_VERSION.tar.gz"
echo "+ ./configure --prefix=$OUTPUT_DIR --enable-static --disable-shared CFLAGS='-O2 -fvisibility=hidden'"
./configure --prefix="$OUTPUT_DIR" --enable-static --disable-shared CFLAGS='-O2 -fvisibility=hidden'
echo "+ make -j$CONCURRENCY"
make -j"$CONCURRENCY"
echo "+ make install-strip"
make install-strip
