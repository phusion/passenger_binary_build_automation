#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate
S3CMD_VERSION=`cat /pbba_build/shared/definitions/s3cmd_version`

header "Installing s3cmd"
cd /tmp
download_and_extract s3cmd-$S3CMD_VERSION.tar.gz \
	s3cmd-$S3CMD_VERSION \
	https://github.com/s3tools/s3cmd/releases/download/v$S3CMD_VERSION/s3cmd-$S3CMD_VERSION.tar.gz
run mkdir -p /hbb/s3cmd
run cp -pR * /hbb/s3cmd/
run cp /pbba_build/linux/docker_image/support/s3cmd_wrapper.sh /hbb/bin/s3cmd

run pip install python-dateutil
