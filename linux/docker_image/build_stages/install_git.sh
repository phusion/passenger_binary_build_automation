#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate
GIT_VERSION=`cat /pbba_build/shared/definitions/git_version`

header "Installing Git"
cd /tmp
run_yum_install expat-devel gettext
download_and_extract git-$GIT_VERSION.tar.gz git-$GIT_VERSION \
	https://github.com/git/git/archive/v$GIT_VERSION.tar.gz
run make -j2 prefix=/hbb install
run rm -rf /hbb/lib/perl5/site_perl/*/Git*

set -o pipefail

binaries=`file /hbb/bin/git* | grep ELF | awk '{ print $1 }' | sed 's/://'`
run strip --strip-all $binaries

binaries=`file /hbb/libexec/git-core/* | grep ELF | awk '{ print $1 }' | sed 's/://'`
run strip --strip-all $binaries
