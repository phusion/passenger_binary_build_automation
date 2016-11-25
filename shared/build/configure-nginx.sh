#!/bin/bash
set -e
EXTRA_ARGS=()

# In the macOS build environment, 'cc' already points to a wrapper script
# that calls ccache. In all other environments, call ccache explicitly.
if [[ -e /hbb ]]; then
	EXTRA_ARGS+=(--with-cc="ccache cc")
fi

# Pass Holy Build Box ldflags to the Nginx build system,
# if available.
if [[ "$LDFLAGS" != "" ]]; then
	EXTRA_ARGS+=(--with-ld-opt="$LDFLAGS")
fi

set -x
exec ./configure "${EXTRA_ARGS[@]}" "$@"
