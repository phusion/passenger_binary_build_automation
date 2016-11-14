#!/bin/bash
set -e
source /hbb_exe_gc_hardened/activate
export EXTRA_CFLAGS="$CFLAGS"
export EXTRA_CXXFLAGS="$CXXFLAGS"
export EXTRA_LDFLAGS="$LDFLAGS"
exec "$@"
