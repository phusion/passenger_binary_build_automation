#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate
LIBPSL_VERSION=$(cat /pbba_build/shared/definitions/libpsl_version)

header "Installing libpsl"
cd /tmp

download_and_extract libpsl-$LIBPSL_VERSION.tar.gz \
		     libpsl-$LIBPSL_VERSION \
		     https://github.com/rockdaboot/libpsl/releases/download/${LIBPSL_VERSION}/libpsl-${LIBPSL_VERSION}.tar.gz

run rm -f "/tmp/libpsl-$LIBPSL_VERSION.tar.gz"
run ./configure --prefix="/hbb"
run make -j2
run make install
