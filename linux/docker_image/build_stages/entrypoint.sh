#!/bin/bash
set -e
SELFDIR=`dirname "$0"`
SELFDIR=`cd "$SELFDIR" && pwd`

touch /var/lib/rpm/*
"$SELFDIR"/essentials.sh
"$SELFDIR"/install_libiconv.sh
"$SELFDIR"/install_gnupg.sh
"$SELFDIR"/install_libcurl.sh
"$SELFDIR"/install_git.sh
"$SELFDIR"/install_s3cmd.sh
"$SELFDIR"/install_pcre.sh
"$SELFDIR"/install_pcre2.sh
"$SELFDIR"/install_geoip.sh
"$SELFDIR"/install_libreadline.sh
"$SELFDIR"/install_libffi.sh
"$SELFDIR"/install_libyaml.sh
"$SELFDIR"/install_rvm.sh
"$SELFDIR"/install_ruby.sh
"$SELFDIR"/cleanup.sh
