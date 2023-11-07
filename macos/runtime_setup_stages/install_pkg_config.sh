#!/bin/bash
set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
source "$ROOTDIR/shared/lib/library.sh"

PKG_CONFIG_VERSION=$(cat "$ROOTDIR/shared/definitions/pkg_config_version")

header "Installing pkg-config $PKG_CONFIG_VERSION"
download_and_extract "pkg-config-$PKG_CONFIG_VERSION.tar.gz" \
	"pkg-config-$PKG_CONFIG_VERSION" \
	"https://pkg-config.freedesktop.org/releases/pkg-config-$PKG_CONFIG_VERSION.tar.gz"
echo "+ rm -f $WORKDIR/pkg-config-$PKG_CONFIG_VERSION.tar.gz"
rm -f "$WORKDIR/pkg-config-$PKG_CONFIG_VERSION.tar.gz"
echo "+ ./configure --prefix=$OUTPUT_DIR --with-internal-glib || ( cat config.log && false )"
./configure --prefix="$OUTPUT_DIR" --with-internal-glib || ( cat config.log && false )
echo "+ make -j$CONCURRENCY"
make -j"$CONCURRENCY"
echo "+ make install-strip"
make install-strip
