#!/bin/bash
set -e
exec /hbb/bin/python /hbb/s3cmd/s3cmd "$@"
