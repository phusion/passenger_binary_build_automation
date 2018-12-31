#!/bin/bash
set -e
source /hbb_shlib/activate
export CFLAGS="$SHLIB_CFLAGS"
export LDFLAGS="$SHLIB_LDFLAGS"
export DLDFLAGS="--as-needed"
export LOCAL_LIBS="--as-needed"
export EXTRA_CFLAGS="$SHLIB_CFLAGS"
export EXTRA_CXXFLAGS="$SHLIB_CXXFLAGS"
export EXTRA_LDFLAGS="$SHLIB_LDFLAGS"
exec "$@"
