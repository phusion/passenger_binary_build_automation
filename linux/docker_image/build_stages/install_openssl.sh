#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate
OPENSSL_VERSION=$(cat "/pbba_build/shared/definitions/openssl_version")

header "Installing OpenSSL $OPENSSL_VERSION"
cd /tmp
download_and_extract openssl-$OPENSSL_VERSION.tar.gz \
		     openssl-$OPENSSL_VERSION \
		     https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz
run rm -f "/tmp/openssl-$OPENSSL_VERSION.tar.gz"
run ./Configure "linux-$(uname -m)" \
	-Wno-nullability-completeness \
	--prefix="/hbb" --openssldir="/hbb/openssl" \
	threads zlib no-shared no-sse2 -fvisibility=hidden
# For some reason the -j1 is explicitly required. If this script was invoked
# from a parent Makefile which was run by `make -j2`, then that parent make
# could somehow pass the -j2 to sub-makes.
run make -j1
run make install_sw

run strip "/hbb/bin/openssl"

if [ "$(uname -m)" = "x86_64" ]; then
    LIBS="/hbb/lib64"
else
    LIBS="/hbb/lib"
fi

run strip -S "$LIBS/libssl.a"
run strip -S "$LIBS/libcrypto.a"

run sed -i'' 's/^Libs:.*/Libs: -L${libdir} -lssl -lcrypto -ldl/' $LIBS/pkgconfig/openssl.pc
run sed -i'' 's/^Libs.private:.*/Libs.private: -L${libdir} -lssl -lcrypto -ldl -lz/' $LIBS/pkgconfig/openssl.pc
run sed -i'' 's/^Libs:.*/Libs: -L${libdir} -lssl -lcrypto -ldl/' $LIBS/pkgconfig/libssl.pc
run sed -i'' 's/^Libs.private:.*/Libs.private: -L${libdir} -lssl -lcrypto -ldl -lz/' $LIBS/pkgconfig/libssl.pc
