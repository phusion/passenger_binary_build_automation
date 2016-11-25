#!/bin/bash

set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

require_envvar WORKDIR "$WORKDIR"
require_envvar INPUT_DIR "$INPUT_DIR"
require_envvar VERSION "$VERSION"
require_envvar FILE_SERVER_PASSWORD "$FILE_SERVER_PASSWORD"
require_envvar REPOSITORY_NAME "$REPOSITORY_NAME"
require_envvar S3_BUCKET_NAME "$S3_BUCKET_NAME"
require_envvar AWS_ACCESS_KEY "$AWS_ACCESS_KEY"
require_envvar AWS_SECRET_KEY "$AWS_SECRET_KEY"


if [[ -e /usr/bin/sw_vers ]]; then
	# On macOS
	GPG=/usr/local/bin/gpg
else
	GPG=gpg
fi


run mkdir "$WORKDIR/content"

FILES=("$INPUT_DIR"/*.gz)
for FILE in "${FILES[@]}"; do
	BASENAME="`basename "$FILE"`"
	run cp "$FILE" "$WORKDIR/content/"
	run $GPG $GPG_OPTS --armor --local-user $GPG_SIGNING_KEY --detach-sign \
		"$WORKDIR/content/$BASENAME"
done

run env GZIP=-1 tar -czf "$WORKDIR/content.tar.gz" -C "$WORKDIR/content" .

echo "user = \"api:$FILE_SERVER_PASSWORD\"" > "$WORKDIR/curl.cfg"
run curl --fail -L -K "$WORKDIR/curl.cfg" \
	-F content=@"$WORKDIR/content.tar.gz" \
	-F repository="$REPOSITORY_NAME" \
	-F subdir="$VERSION" \
	https://oss-binaries.phusionpassenger.com/binary_build_automation/add

cat >>"$WORKDIR/s3cfg" <<EOF
access_key = $AWS_ACCESS_KEY
secret_key = $AWS_SECRET_KEY
EOF
run s3cmd -c "$WORKDIR/s3cfg" \
	--storage-class=STANDARD_IA \
	--human-readable-sizes \
	--follow-symlinks \
	--skip-existing \
	--no-delete-removed \
	--acl-public \
	--guess-mime-type \
	sync \
	"$WORKDIR/content/" \
	"s3://phusion-passenger/binaries/$S3_BUCKET_NAME/by_release/$VERSION/"
