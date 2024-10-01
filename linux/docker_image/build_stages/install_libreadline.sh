#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate
READLINE_VERSION=$(cat /pbba_build/shared/definitions/libreadline_version)

header "Installing libreadline $READLINE_VERSION"
cd /tmp
download_and_extract readline-$READLINE_VERSION.tar.gz \
		     readline-$READLINE_VERSION \
		     https://ftp.gnu.org/gnu/readline/readline-$READLINE_VERSION.tar.gz
run rm -f "/tmp/readline-$READLINE_VERSION.tar.gz"
run ./configure --prefix="/hbb"
run make -j2
run make install
