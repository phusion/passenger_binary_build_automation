#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

GEOIP_VERSION=$(cat "$ROOTDIR/shared/definitions/geoip_version")

header "Installing libcurl $GEOIP_VERSION"
download_and_extract GeoIP-$GEOIP_VERSION.tar.gz \
	GeoIP-$GEOIP_VERSION \
	https://github.com/maxmind/geoip-api-c/releases/download/v$GEOIP_VERSION/GeoIP-$GEOIP_VERSION.tar.gz
run rm -f "$WORKDIR/GeoIP-$GEOIP_VERSION.tar.gz"
run ./configure --prefix="$OUTPUT_DIR" \
	--enable-static --disable-shared \
	CFLAGS='-O2 -fvisibility=hidden'
run make -j$CONCURRENCY
run make install-strip
