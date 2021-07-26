#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

CURL_VERSION=$(cat "$ROOTDIR/shared/definitions/curl_version")

header "Installing libcurl $CURL_VERSION"
download_and_extract curl-$CURL_VERSION.tar.gz \
		     curl-$CURL_VERSION \
		     https://curl.haxx.se/download/curl-$CURL_VERSION.tar.gz

if [ "$(curl-config --configure | fgrep libressl)" ]; then
	TLS_LIB="--with-openssl --with-ca-bundle=/etc/ssl/cert.pem --with-ca-path=/etc/ssl/certs/"
else
	TLS_LIB="--with-secure-transport --without-ca-bundle --without-ca-path"
fi

run rm -f "$WORKDIR/curl-$CURL_VERSION.tar.gz"
run ./configure --prefix="$OUTPUT_DIR" \
    --disable-shared --disable-debug --enable-optimize --disable-werror \
    --disable-curldebug --enable-symbol-hiding --disable-ares --disable-manual --disable-ldap --disable-ldaps \
    --disable-rtsp --disable-dict --disable-ftp --disable-ftps --disable-gopher --disable-imap \
    --disable-imaps --disable-pop3 --disable-pop3s --without-librtmp --disable-smtp --disable-smtps \
    --disable-telnet --disable-tftp --disable-smb --disable-versioned-symbols \
    --without-libmetalink --without-libidn2 --without-libssh2 --without-nghttp2 \
    ${TLS_LIB}
run make -j$CONCURRENCY
run make install-strip
run rm -f "$OUTPUT_DIR/bin/curl"
