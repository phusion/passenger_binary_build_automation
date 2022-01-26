#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb_exe_gc_hardened/activate
PCRE_VERSION=`cat /pbba_build/shared/definitions/pcre_version`

export CFLAGS="$STATICLIB_CFLAGS"
export CXXFLAGS="$STATICLIB_CXXFLAGS"

header "Installing PCRE"
cd /tmp
download_and_extract pcre-$PCRE_VERSION.tar.gz pcre-$PCRE_VERSION \
	https://sourceforge.net/projects/pcre/files/pcre/${PCRE_VERSION}/pcre-${PCRE_VERSION}.tar.gz/download
run ./configure --prefix=/hbb_exe_gc_hardened --enable-static --disable-shared
run make -j2
run make install-strip
