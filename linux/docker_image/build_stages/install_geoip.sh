#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb_exe_gc_hardened/activate
GEOIP_VERSION=`cat /pbba_build/shared/definitions/geoip_version`

export CFLAGS="$STATICLIB_CFLAGS"
export CXXFLAGS="$STATICLIB_CXXFLAGS"

header "Installing GeoIP"
cd /tmp
download_and_extract GeoIP-$GEOIP_VERSION.tar.gz GeoIP-$GEOIP_VERSION \
	https://github.com/maxmind/geoip-api-c/releases/download/v$GEOIP_VERSION/GeoIP-$GEOIP_VERSION.tar.gz
run ./configure --prefix=/hbb_exe_gc_hardened --enable-static --disable-shared
run make -j2
run make install-strip
