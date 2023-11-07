#!/bin/bash
set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
source "$ROOTDIR/shared/lib/library.sh"

ZSTD_VERSION=$(cat "$ROOTDIR/shared/definitions/zstd_version")

header "Installing zstd $ZSTD_VERSION"
download_and_extract "zstd-${ZSTD_VERSION}.tar.gz" \
	"zstd-${ZSTD_VERSION}" \
	"https://github.com/facebook/zstd/releases/download/v${ZSTD_VERSION}/zstd-${ZSTD_VERSION}.tar.gz"
echo "+ rm -f $WORKDIR/zstd-${ZSTD_VERSION}.tar.gz"
rm -f "$WORKDIR/zstd-${ZSTD_VERSION}.tar.gz"
cd lib
echo "+ make -j$CONCURRENCY install-static PREFIX=$OUTPUT_DIR"
make -j"$CONCURRENCY" install-static PREFIX="$OUTPUT_DIR"
echo "+ strip -S $OUTPUT_DIR/lib/libzstd.a"
strip -S "$OUTPUT_DIR/lib/libzstd.a"
