#!/bin/bash
set -e
source /hbb_shlib/activate
export CFLAGS="-Wl,--as-needed $SHLIB_CFLAGS"
export LDFLAGS="--as-needed $SHLIB_LDFLAGS"
export EXTRA_CFLAGS="-Wl,--as-needed $SHLIB_CFLAGS"
export EXTRA_CXXFLAGS="-Wl,--as-needed $SHLIB_CXXFLAGS"
export EXTRA_LDFLAGS="--as-needed $SHLIB_LDFLAGS"
exec "$@"
