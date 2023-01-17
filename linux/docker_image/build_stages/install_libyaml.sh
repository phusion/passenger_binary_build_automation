#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate
LIBYAML_VERSION=$(cat /pbba_build/shared/definitions/libyaml_version)

header "Installing libyaml $LIBYAML_VERSION"
cd /tmp
download_and_extract libyaml-$LIBYAML_VERSION.tar.gz \
		     yaml-$LIBYAML_VERSION \
		     https://github.com/yaml/libyaml/releases/download/${LIBYAML_VERSION}/yaml-${LIBYAML_VERSION}.tar.gz
run rm -f "/tmp/libyaml-$LIBYAML_VERSION.tar.gz"
run ./configure --prefix="/hbb"
run make -j2
run make install
