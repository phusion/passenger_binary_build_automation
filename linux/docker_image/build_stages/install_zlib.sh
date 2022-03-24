#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate
ZLIB_VERSION=$(cat /pbba_build/shared/definitions/zlib_version)

header "Installing zlib"
cd /tmp
download_and_extract zlib-$ZLIB_VERSION.tar.gz zlib-$ZLIB_VERSION \
		     https://zlib.net/fossils/zlib-$ZLIB_VERSION.tar.gz
run env CFLAGS='-O2 -fvisibility=hidden' ./configure --prefix=/hbb --static
run make -j2
run make install
run strip -S "/hbb/lib/libz.a"
