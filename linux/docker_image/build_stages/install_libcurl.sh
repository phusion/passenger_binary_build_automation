#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate
CURL_VERSION=$(cat /pbba_build/shared/definitions/curl_version)

header "Installing libcurl $CURL_VERSION"
cd /tmp
download_and_extract curl-$CURL_VERSION.tar.gz \
		     curl-$CURL_VERSION \
		     https://curl.se/download/curl-$CURL_VERSION.tar.gz
run rm -f "/tmp/curl-$CURL_VERSION.tar.gz"
run ./configure --prefix="/hbb" \
    --disable-shared --disable-debug --enable-optimize --disable-werror \
    --disable-curldebug --enable-symbol-hiding --disable-ares --disable-manual --disable-ldap --disable-ldaps \
    --disable-rtsp --disable-dict --disable-ftp --disable-ftps --disable-gopher --disable-imap \
    --disable-imaps --disable-pop3 --disable-pop3s --without-librtmp --disable-smtp --disable-smtps \
    --disable-telnet --disable-tftp --disable-smb --disable-versioned-symbols \
    --without-libmetalink --without-libidn2 --without-libssh2 --without-libmetalink --without-nghttp2
run make -j2
run make install-strip
