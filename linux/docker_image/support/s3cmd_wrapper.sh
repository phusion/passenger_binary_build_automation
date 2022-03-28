#!/bin/bash
set -e
exec /usr/bin/env python /hbb/s3cmd/s3cmd "$@"
