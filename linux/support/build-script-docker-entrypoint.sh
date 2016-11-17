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
		rake -f /system/shared/build/Rakefile -T
else
	export PASSENGER_DIR=/passenger
	export CACHE_DIR=/cache
	export OUTPUT_DIR=/output
	export IN_HOLY_BUILD_BOX=true
	if [[ -e /nginx ]]; then
		export NGINX_DIR=/nginx
	fi

	export USE_CCACHE=true
	export CCACHE_SLOPPINESS=time_macros
	export CCACHE_NOHASHDIR=true
	unset CCACHE_HASHDIR

	run mkdir -p "$CCACHE_DIR" /work
	run chown builder: /cache "$CCACHE_DIR" /work

	run setuser builder \
		/usr/local/rvm/bin/rvm-exec ruby-$LAST_RUBY_VERSION \
		env OUTPUT_DIR=/work \
		drake -f /system/shared/build/Rakefile "$@"

	run chown -R "$APP_UID:$APP_GID" /work
	if [[ -e /work/support-binaries ]]; then
		run rm -rf "$OUTPUT_DIR/support-binaries"
		run mv /work/support-binaries "$OUTPUT_DIR/"
	fi
	if [[ -e /work/ruby-extensions ]]; then
		run rm -rf "$OUTPUT_DIR/ruby-extensions"
		run mv /work/ruby-extensions "$OUTPUT_DIR/"
	fi
fi
