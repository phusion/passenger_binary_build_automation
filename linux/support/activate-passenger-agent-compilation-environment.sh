#!/bin/bash
set -e
source /hbb_exe_gc_hardened/activate
# Remove -O2 because the Passenger build system already
# sets optimization flags.
export EXTRA_CFLAGS=`echo "$CFLAGS" | sed 's/-O2//'`
export EXTRA_CXXFLAGS=`eco "$CXXFLAGS" | sed 's/-O2//'`
export EXTRA_LDFLAGS="$LDFLAGS"
exec "$@"
