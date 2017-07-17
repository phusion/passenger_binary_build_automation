#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

OPENSSL_VERSION=$(cat "$ROOTDIR/shared/definitions/openssl_version")

header "Installing OpenSSL $OPENSSL_VERSION"
download_and_extract openssl-$OPENSSL_VERSION.tar.gz \
	openssl-$OPENSSL_VERSION \
	https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
run rm -f "$WORKDIR/openssl-$OPENSSL_VERSION.tar.gz"
run ./Configure darwin64-x86_64-cc \
	--prefix="$OUTPUT_DIR" --openssldir="$OUTPUT_DIR/openssl" \
	threads zlib no-shared no-sse2 -fvisibility=hidden
# For some reason the -j1 is explicitly required. If this script was invoked
# from a parent Makefile which was run by `make -j2`, then that parent make
# could somehow pass the -j2 to sub-makes.
run make -j1
run make install_sw

run strip "$OUTPUT_DIR/bin/openssl"
run strip -S "$OUTPUT_DIR/lib/libssl.a"
run strip -S "$OUTPUT_DIR/lib/libcrypto.a"

run sed -i '' 's/^Libs:.*/Libs: -L${libdir} -lssl -lcrypto -ldl/' "$OUTPUT_DIR"/lib/pkgconfig/openssl.pc
run sed -i '' 's/^Libs.private:.*/Libs.private: -L${libdir} -lssl -lcrypto -ldl -lz/' "$OUTPUT_DIR"/lib/pkgconfig/openssl.pc
run sed -i '' 's/^Libs:.*/Libs: -L${libdir} -lssl -lcrypto -ldl/' "$OUTPUT_DIR"/lib/pkgconfig/libssl.pc
run sed -i '' 's/^Libs.private:.*/Libs.private: -L${libdir} -lssl -lcrypto -ldl -lz/' "$OUTPUT_DIR"/lib/pkgconfig/libssl.pc
