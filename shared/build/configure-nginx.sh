#!/bin/bash
set -e
EXTRA_ARGS=()

# Pass Holy Build Box ldflags to the Nginx build system,
# if available.
if [[ "$LDFLAGS" != "" ]]; then
	EXTRA_ARGS+=(--with-ld-opt="$LDFLAGS")
fi

set -x
exec ./configure "${EXTRA_ARGS[@]}" "$@"
