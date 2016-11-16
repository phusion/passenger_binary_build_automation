#!/bin/bash
set -e
SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`

"$SELFDIR"/essentials.sh
"$SELFDIR"/install_geoip.sh
"$SELFDIR"/install_git.sh
"$SELFDIR"/install_pcre.sh
"$SELFDIR"/install_rvm.sh
"$SELFDIR"/install_ruby.sh
"$SELFDIR"/cleanup.sh
