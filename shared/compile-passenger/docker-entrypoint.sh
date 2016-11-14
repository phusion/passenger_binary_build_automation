#!/bin/bash
set -e
source /hbb/activate
source /system/shared/lib/library.sh

RUBY_VERSIONS=(`cat /system/shared/definitions/ruby_versions`)
LAST_RUBY_VERSION=${RUBY_VERSIONS[${#RUBY_VERSIONS[@]} - 1]}

export CCACHE_DIR=/cache/ccache
export CCACHE_COMPRESS=1
export CCACHE_COMPRESS_LEVEL=3

run mkdir -p "$CCACHE_DIR"
run chown builder: "$CCACHE_DIR" /output

run setuser builder \
	/usr/local/rvm/bin/rvm-exec ruby-$LAST_RUBY_VERSION \
	ruby /system/shared/compile-passenger/compile-passenger.rb \
	--passenger-dir /passenger \
	--concurrency $CONCURRENCY \
	--inside-holy-build-box \
	--output-dir /output
