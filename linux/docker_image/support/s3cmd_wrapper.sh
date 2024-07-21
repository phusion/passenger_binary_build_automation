#!/bin/bash
set -e
exec /usr/bin/env python2 /hbb/s3cmd/s3cmd "$@"
