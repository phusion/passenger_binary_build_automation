#!/bin/bash
set -e
source /hbb/activate
source /system/shared/lib/library.sh

RUBY_VERSIONS=(`cat /system/shared/definitions/ruby_versions`)
LAST_RUBY_VERSION=${RUBY_VERSIONS[${#RUBY_VERSIONS[@]} - 1]}

export CCACHE_DIR=/cache/ccache
export CCACHE_COMPRESS=1
export CCACHE_COMPRESSLEVEL=3

if $SHOW_TASKS; then
	exec setuser builder \
		/usr/local/rvm/bin/rvm-exec ruby-$LAST_RUBY_VERSION \
		rake -f /system/shared/build-passenger/Rakefile -T
else
	export PASSENGER_DIR=/passenger
	export CACHE_DIR=/cache
	export OUTPUT_DIR=/output
	export IN_HOLY_BUILD_BOX=true
	if [[ -e /nginx ]]; then
		export NGINX_DIR=/nginx
	fi

	run mkdir -p "$CCACHE_DIR"
	run chown builder: "$CCACHE_DIR" /output /cache

	run setuser builder \
		/usr/local/rvm/bin/rvm-exec ruby-$LAST_RUBY_VERSION \
		drake -f /system/shared/build-passenger/Rakefile "$@"
fi
