#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/.." && pwd`
exec python "$ROOTDIR/s3cmd/s3cmd" "$@"
