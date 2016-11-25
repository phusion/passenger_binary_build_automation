#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

S3CMD_VERSION=$(cat "$ROOTDIR/shared/definitions/s3cmd_version")

header "Installing s3cmd $S3CMD_VERSION"
download_and_extract s3cmd-$S3CMD_VERSION.tar.gz \
	s3cmd-$S3CMD_VERSION \
	https://github.com/s3tools/s3cmd/releases/download/v$S3CMD_VERSION/s3cmd-$S3CMD_VERSION.tar.gz
run rm -f /tmp/s3cmd-$S3CMD_VERSION.tar.gz
run mkdir -p "$OUTPUT_DIR/s3cmd"
run cp -pR * "$OUTPUT_DIR/s3cmd/"
run cp "$ROOTDIR/macos/runtime_setup_stages/s3cmd_wrapper.sh" "$OUTPUT_DIR/bin/s3cmd"
