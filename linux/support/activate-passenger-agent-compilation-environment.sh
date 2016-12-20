#!/bin/bash
set -e
set -o pipefail
source /hbb_exe_gc_hardened/activate
# Remove -O2 because the Passenger build system already
# sets optimization flags.
export EXTRA_CFLAGS=`echo "$CFLAGS" | sed 's/-O2//'`
export EXTRA_CXXFLAGS=`echo "$CXXFLAGS" | sed 's/-O2//'`
export EXTRA_LDFLAGS="$LDFLAGS"

COMMON_FLAGS="-DCURL_IS_STATICALLY_LINKED"
export EXTRA_CFLAGS="$EXTRA_CFLAGS $COMMON_FLAGS"
export EXTRA_CXXFLAGS="$EXTRA_CXXFLAGS $COMMON_FLAGS"

exec "$@"
