#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate
LIBGPG_ERROR_VERSION=`cat /pbba_build/shared/definitions/libgpg_error_version`
LIBGCRYPT_VERSION=`cat /pbba_build/shared/definitions/libgcrypt_version`
LIBKSBA_VERSION=`cat /pbba_build/shared/definitions/libksba_version`
LIBASSUAN_VERSION=`cat /pbba_build/shared/definitions/libassuan_version`
NPTH_VERSION=`cat /pbba_build/shared/definitions/npth_version`
PINENTRY_VERSION=`cat /pbba_build/shared/definitions/pinentry_version`
GNUPG_VERSION=`cat /pbba_build/shared/definitions/gnupg_version`

header "Installing libgpg-error"
cd /tmp
download_and_extract libgpg-error-$LIBGPG_ERROR_VERSION.tar.bz2 libgpg-error-$LIBGPG_ERROR_VERSION \
	https://www.gnupg.org/ftp/gcrypt/libgpg-error/libgpg-error-$LIBGPG_ERROR_VERSION.tar.bz2
run ./configure --prefix=/hbb --disable-static
run make -j2
run make install-strip

header "Installing libgcrypt"
cd /tmp
download_and_extract libgcrypt-$LIBGCRYPT_VERSION.tar.bz2 libgcrypt-$LIBGCRYPT_VERSION \
	https://www.gnupg.org/ftp/gcrypt/libgcrypt/libgcrypt-$LIBGCRYPT_VERSION.tar.bz2
run ./configure --prefix=/hbb --disable-static
run make -j2
run make install-strip

header "Installing libksba"
cd /tmp
download_and_extract libksba-$LIBKSBA_VERSION.tar.bz2 libksba-$LIBKSBA_VERSION \
	https://www.gnupg.org/ftp/gcrypt/libksba/libksba-$LIBKSBA_VERSION.tar.bz2
run ./configure --prefix=/hbb --disable-static
run make -j2
run make install-strip

header "Installing libassuan"
cd /tmp
download_and_extract libassuan-$LIBASSUAN_VERSION.tar.bz2 libassuan-$LIBASSUAN_VERSION \
	https://www.gnupg.org/ftp/gcrypt/libassuan/libassuan-$LIBASSUAN_VERSION.tar.bz2
run ./configure --prefix=/hbb --disable-static
run make -j2
run make install-strip

header "Installing nPth"
cd /tmp
download_and_extract npth-$NPTH_VERSION.tar.bz2 npth-$NPTH_VERSION \
	https://www.gnupg.org/ftp/gcrypt/npth/npth-$NPTH_VERSION.tar.bz2
run ./configure --prefix=/hbb
run make -j2
run make install-strip

header "Installing pinentry"
cd /tmp
download_and_extract pinentry-$PINENTRY_VERSION.tar.bz2 pinentry-$PINENTRY_VERSION \
	https://www.gnupg.org/ftp/gcrypt/pinentry/pinentry-$PINENTRY_VERSION.tar.bz2
run ./configure --prefix=/hbb \
	--enable-pinentry-curses \
	--enable-pinentry-tty \
	--disable-pinentry-qt5
run make -j2
run make install-strip

header "Installing GnuPG"
# Monkey patch inotify headers to make GnuPG 2.1 compile successfully
run sed -i 's/#define IN_DELETE_SELF/#define IN_EXCL_UNLINK 0x04000000\n#define IN_DELETE_SELF/' /usr/include/sys/inotify.h
cd /tmp
download_and_extract gnupg-$GNUPG_VERSION.tar.bz2 gnupg-$GNUPG_VERSION \
	https://www.gnupg.org/ftp/gcrypt/gnupg/gnupg-$GNUPG_VERSION.tar.bz2
run ./configure --prefix=/hbb --with-pinentry-pgm=/hbb/bin/pinentry
run make -j2
run make install-strip
run ln -s /hbb/bin/gpg2 /hbb/bin/gpg
