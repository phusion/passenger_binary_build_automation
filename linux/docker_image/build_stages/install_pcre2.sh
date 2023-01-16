#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb_exe_gc_hardened/activate
PCRE2_VERSION=`cat /pbba_build/shared/definitions/pcre2_version`

export CFLAGS="$STATICLIB_CFLAGS"
export CXXFLAGS="$STATICLIB_CXXFLAGS"

header "Installing PCRE2"
cd /tmp
download_and_extract pcre2-$PCRE2_VERSION.tar.gz pcre2-$PCRE2_VERSION \
	https://github.com/PCRE2Project/pcre2/releases/download/pcre2-$PCRE2_VERSION/pcre2-$PCRE2_VERSION.tar.gz
run ./configure --prefix=/hbb_exe_gc_hardened --enable-static --disable-shared
run make -j2
run make install-strip
