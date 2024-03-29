#!/bin/bash
set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
source "$ROOTDIR/shared/lib/library.sh"

LIBPSL_VERSION=$(cat "$ROOTDIR/shared/definitions/libpsl_version")

header "Installing libpsl $LIBPSL_VERSION"
download_and_extract libpsl-$LIBPSL_VERSION.tar.gz \
		     libpsl-$LIBPSL_VERSION \
		     https://github.com/rockdaboot/libpsl/releases/download/${LIBPSL_VERSION}/libpsl-${LIBPSL_VERSION}.tar.gz

run rm -f "$WORKDIR/libpsl-$LIBPSL_VERSION.tar.gz"
run ./configure --prefix="$OUTPUT_DIR" --disable-shared
run make "-j$CONCURRENCY"
run make install
