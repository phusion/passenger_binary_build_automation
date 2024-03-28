#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate
OPENSSL_VERSION=$(cat /pbba_build/shared/definitions/openssl_version)

header "Installing openssl"
cd /tmp

download_and_extract openssl-$OPENSSL_VERSION.tar.gz \
		     openssl-$OPENSSL_VERSION \
		     https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz

run rm -f "/tmp/openssl-$OPENSSL_VERSION.tar.gz"
run ./Configure "linux-$(uname -m)" \
    --prefix="/hbb" --openssldir="/hbb/openssl" \
    threads zlib no-shared no-sse2 -fvisibility=hidden

run make -j2
run make install_sw
run strip "/hbb/bin/openssl"
run strip -S "/hbb/lib/libssl.a"
run strip -S "/hbb/lib/libcrypto.a"

run sed --in-place -e 's/^Libs:.*/Libs: -L${libdir} -lssl -lcrypto -ldl/' "/hbb/lib/pkgconfig/openssl.pc"
run sed --in-place -e 's/^Libs.private:.*/Libs.private: -L${libdir} -lssl -lcrypto -ldl -lz/' "/hbb/lib/pkgconfig/openssl.pc"
run sed --in-place -e 's/^Libs:.*/Libs: -L${libdir} -lssl -lcrypto -ldl/' "/hbb/lib/pkgconfig/libssl.pc"
run sed --in-place -e 's/^Libs.private:.*/Libs.private: -L${libdir} -lssl -lcrypto -ldl -lz/' "/hbb/lib/pkgconfig/libssl.pc"
