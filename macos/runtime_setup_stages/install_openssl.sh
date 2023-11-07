#!/bin/bash
set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
source "$ROOTDIR/shared/lib/library.sh"

OPENSSL_VERSION=$(cat "$ROOTDIR/shared/definitions/openssl_version")

header "Installing OpenSSL $OPENSSL_VERSION"
download_and_extract "openssl-$OPENSSL_VERSION.tar.gz" \
	"openssl-$OPENSSL_VERSION" \
	"https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz"
echo "+ rm -f $WORKDIR/openssl-$OPENSSL_VERSION.tar.gz"
rm -f "$WORKDIR/openssl-$OPENSSL_VERSION.tar.gz"

echo "+ ./Configure darwin64-$(uname -m)-cc -I/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include -Wno-nullability-completeness --prefix=$OUTPUT_DIR --openssldir=$OUTPUT_DIR/openssl threads zlib no-shared no-sse2 -fvisibility=hidden"
./Configure "darwin64-$(uname -m)-cc" \
	-I/Library/Developer/CommandLineTools/SDKs/MacOSX.sdk/usr/include \
	-Wno-nullability-completeness \
	--prefix="$OUTPUT_DIR" --openssldir="$OUTPUT_DIR/openssl" \
	threads zlib no-shared no-sse2 -fvisibility=hidden
# For some reason the -j1 is explicitly required. If this script was invoked
# from a parent Makefile which was run by `make -j2`, then that parent make
# could somehow pass the -j2 to sub-makes.
echo "+ make -j1"
make -j1
echo "+ make install_sw"
make install_sw

echo "+ strip $OUTPUT_DIR/bin/openssl"
strip "$OUTPUT_DIR/bin/openssl"
echo "+ strip -S $OUTPUT_DIR/lib/libssl.a"
strip -S "$OUTPUT_DIR/lib/libssl.a"
echo "+ strip -S $OUTPUT_DIR/lib/libcrypto.a"
strip -S "$OUTPUT_DIR/lib/libcrypto.a"

echo "+ sed -i '' 's/^Libs:.*/Libs: -L\${libdir} -lssl -lcrypto -ldl/' $OUTPUT_DIR/lib/pkgconfig/openssl.pc"
sed -i '' 's/^Libs:.*/Libs: -L${libdir} -lssl -lcrypto -ldl/' "$OUTPUT_DIR"/lib/pkgconfig/openssl.pc
echo "+ sed -i '' 's/^Libs.private:.*/Libs.private: -L\${libdir} -lssl -lcrypto -ldl -lz/' $OUTPUT_DIR/lib/pkgconfig/openssl.pc"
sed -i '' 's/^Libs.private:.*/Libs.private: -L${libdir} -lssl -lcrypto -ldl -lz/' "$OUTPUT_DIR"/lib/pkgconfig/openssl.pc
echo "+ sed -i '' 's/^Libs:.*/Libs: -L\${libdir} -lssl -lcrypto -ldl/' $OUTPUT_DIR/lib/pkgconfig/libssl.pc"
sed -i '' 's/^Libs:.*/Libs: -L${libdir} -lssl -lcrypto -ldl/' "$OUTPUT_DIR"/lib/pkgconfig/libssl.pc
echo "+ sed -i '' 's/^Libs.private:.*/Libs.private: -L\${libdir} -lssl -lcrypto -ldl -lz/' $OUTPUT_DIR/lib/pkgconfig/libssl.pc"
sed -i '' 's/^Libs.private:.*/Libs.private: -L${libdir} -lssl -lcrypto -ldl -lz/' "$OUTPUT_DIR"/lib/pkgconfig/libssl.pc
