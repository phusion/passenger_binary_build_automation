#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate
LIBICONV_VERSION=`cat /pbba_build/shared/definitions/libiconv_version`
header "Installing libiconv"
cd /tmp
download_and_extract libiconv-$LIBICONV_VERSION.tar.gz libiconv-$LIBICONV_VERSION \
	https://ftp.gnu.org/gnu/libiconv/libiconv-$LIBICONV_VERSION.tar.gz
run ./configure --prefix=/hbb
run make -j2
run make install-strip
