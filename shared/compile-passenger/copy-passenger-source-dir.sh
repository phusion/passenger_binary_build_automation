#!/bin/bash
# Usage: copy-passenger-source-dir.sh <INPUT> <OUTPUT>
# Copies a Passenger source directory to a different place.

set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

require_args_exact 2 "$@"
INPUT_DIR="$1"
OUTPUT_DIR="$2"

header "Creating Passenger official tarball"
# The input directory may be mounted read-only, but 'rake' may have to
# create files, e.g. to generate documentation files. So we copy it to
# a temporary directory which is writable.
run rm -rf "$OUTPUT_DIR"
if [[ -e "$INPUT_DIR"/.git ]]; then
	run mkdir "$OUTPUT_DIR"
	echo "+ cd $INPUT_DIR"
	cd "$INPUT_DIR"
	echo "+ Git copying to $OUTPUT_DIR"
	(
		set -o pipefail
		git archive --format=tar HEAD | tar -C "$OUTPUT_DIR" -x
		submodules=`git submodule status | awk '{ print $2 }'`
		for submodule in $submodules; do
			echo "+ Git copying submodule $submodule"
			pushd "$submodule" >/dev/null
			mkdir -p "$OUTPUT_DIR/$submodule"
			git archive --format=tar HEAD | tar -C "$OUTPUT_DIR/$submodule" -x
			popd >/dev/null
		done
	)
	if [[ $? != 0 ]]; then
		exit 1
	fi

	cd "$OUTPUT_DIR"
else
	run cp -dpR "$INPUT_DIR" "$OUTPUT_DIR"
	cd "$OUTPUT_DIR"
	run rake clean
fi

header "Finalizing source directory"
echo "+ Normalizing timestamps"
find . -print0 | xargs -0 touch -d '2013-10-27 00:00:00 UTC'
