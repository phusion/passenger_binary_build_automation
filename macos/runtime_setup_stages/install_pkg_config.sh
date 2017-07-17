#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

PKG_CONFIG_VERSION=$(cat "$ROOTDIR/shared/definitions/pkg_config_version")

header "Installing pkg-config $PKG_CONFIG_VERSION"
download_and_extract pkg-config-$PKG_CONFIG_VERSION.tar.gz \
	pkg-config-$PKG_CONFIG_VERSION \
	https://pkg-config.freedesktop.org/releases/pkg-config-$PKG_CONFIG_VERSION.tar.gz
run rm -f "$WORKDIR/pkg-config-$PKG_CONFIG_VERSION.tar.gz"
run ./configure --prefix="$OUTPUT_DIR" --with-internal-glib
run make -j$CONCURRENCY
run make install-strip
