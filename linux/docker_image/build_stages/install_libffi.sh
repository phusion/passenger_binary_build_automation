#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate
LIBFFI_VERSION=$(cat /pbba_build/shared/definitions/libffi_version)

header "Installing libffi $LIBFFI_VERSION"
cd /tmp
download_and_extract libffi-$LIBFFI_VERSION.tar.gz \
		     libffi-$LIBFFI_VERSION \
		     https://github.com/libffi/libffi/releases/download/v${LIBFFI_VERSION}/libffi-${LIBFFI_VERSION}.tar.gz
run rm -f "/tmp/libffi-$LIBFFI_VERSION.tar.gz"
run ./configure --prefix="/hbb"
run make -j2
run make install
