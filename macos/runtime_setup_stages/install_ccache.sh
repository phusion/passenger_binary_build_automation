#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

/usr/bin/env -P /usr/local/bin:/opt/homebrew/bin brew install ccache
ln -s "$(/usr/bin/env -P /usr/local/bin:/opt/homebrew/bin brew --prefix ccache)/bin/ccache" "$OUTPUT_DIR/bin/ccache"
