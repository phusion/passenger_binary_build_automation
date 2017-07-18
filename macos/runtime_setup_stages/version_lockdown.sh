#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

MACOS_RUNTIME_VERSION=$(cat "$ROOTDIR/shared/definitions/macos_runtime_version")

if [[ -e "$OUTPUT_DIR/MACOS_RUNTIME_VERSION" ]]; then
	ACTUAL_RUNTIME_VERSION=$(cat "$OUTPUT_DIR/MACOS_RUNTIME_VERSION")
	if [[ "$ACTUAL_RUNTIME_VERSION" != "$MACOS_RUNTIME_VERSION" ]]; then
		echo "ERROR: The directory $OUTPUT_DIR contains a runtime with version number" \
			"$ACTUAL_RUNTIME_VERSION, which is incompatible with our expected" \
			"version $MACOS_RUNTIME_VERSION. Please remove $OUTPUT_DIR and try again."
		exit 1
	fi
else
	echo "$MACOS_RUNTIME_VERSION" > "$OUTPUT_DIR/MACOS_RUNTIME_VERSION"
fi
