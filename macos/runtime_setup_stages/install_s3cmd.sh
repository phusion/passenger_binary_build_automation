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
echo "+ rm -f $WORKDIR/s3cmd-$S3CMD_VERSION.tar.gz"
rm -f "$WORKDIR/s3cmd-$S3CMD_VERSION.tar.gz"
echo "+ mkdir -p $OUTPUT_DIR/s3cmd"
mkdir -p "$OUTPUT_DIR/s3cmd"
echo "+ cp -pR * $OUTPUT_DIR/s3cmd/"
cp -pR * "$OUTPUT_DIR/s3cmd/"
echo "+ cp $ROOTDIR/macos/runtime_setup_stages/s3cmd_wrapper.sh $OUTPUT_DIR/bin/s3cmd"
cp "$ROOTDIR/macos/runtime_setup_stages/s3cmd_wrapper.sh" "$OUTPUT_DIR/bin/s3cmd"
