#!/bin/bash

set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
source "$ROOTDIR/shared/lib/library.sh"

require_envvar WORKDIR "$WORKDIR"
require_envvar INPUT_DIR "$INPUT_DIR"
require_envvar VERSION "$VERSION"
require_envvar FILE_SERVER_PASSWORD "$FILE_SERVER_PASSWORD"
require_envvar REPOSITORY_NAME "$REPOSITORY_NAME"
require_envvar S3_BUCKET_NAME "$S3_BUCKET_NAME"
require_envvar AWS_ACCESS_KEY "$AWS_ACCESS_KEY"
require_envvar AWS_SECRET_KEY "$AWS_SECRET_KEY"
require_envvar TESTING "$TESTING"


if [[ -e /usr/bin/sw_vers ]]; then
	# On macOS
	GPG=/usr/local/bin/gpg
else
	GPG=gpg
fi

echo "+ mkdir $WORKDIR/content"
mkdir "$WORKDIR/content"

FILES=("$INPUT_DIR"/*.gz)
for FILE in "${FILES[@]}"; do
	BASENAME="$(basename "$FILE")"
	echo "+ cp $FILE $WORKDIR/content/"
	cp "$FILE" "$WORKDIR/content/"
	echo "+ $GPG $GPG_OPTS --armor --local-user $GPG_SIGNING_KEY --detach-sign $WORKDIR/content/$BASENAME"
	# not-quoting GPG_OPTS here is deliberate, to work around not being able to export arrays in bash
	$GPG $GPG_OPTS --armor --local-user "$GPG_SIGNING_KEY" --detach-sign "$WORKDIR/content/$BASENAME"
done

echo "+ env GZIP=-1 tar -czf $WORKDIR/content.tar.gz -C $WORKDIR/content ."
env GZIP=-1 tar -czf "$WORKDIR/content.tar.gz" -C "$WORKDIR/content" .

CURL_ARGS=()
if $TESTING; then
	CURL_ARGS+=(-F overwrite=true)
fi
echo "user = \"api:$FILE_SERVER_PASSWORD\"" > "$WORKDIR/curl.cfg"
echo "+ curl --fail -L -K $WORKDIR/curl.cfg -F content=@$WORKDIR/content.tar.gz -F repository=$REPOSITORY_NAME -F subdir=$VERSION ${CURL_ARGS[*]} https://oss-binaries.phusionpassenger.com/binary_build_automation/add"
curl --fail -L -K "$WORKDIR/curl.cfg" \
	-F content=@"$WORKDIR/content.tar.gz" \
	-F repository="$REPOSITORY_NAME" \
	-F subdir="$VERSION" \
	"${CURL_ARGS[@]}" \
	https://oss-binaries.phusionpassenger.com/binary_build_automation/add
echo

S3CMD_ARGS=()
if ! $TESTING; then
	S3CMD_ARGS+=(--skip-existing)
fi
cat >>"$WORKDIR/s3cfg" <<EOF
access_key = $AWS_ACCESS_KEY
secret_key = $AWS_SECRET_KEY
EOF
echo "+ s3cmd -c $WORKDIR/s3cfg	--storage-class=STANDARD_IA --human-readable-sizes --follow-symlinks --no-delete-removed --acl-public --guess-mime-type	${S3CMD_ARGS[*]} sync $WORKDIR/content/	s3://phusion-passenger/binaries/$S3_BUCKET_NAME/by_release/$VERSION/"
s3cmd -c "$WORKDIR/s3cfg" \
	--storage-class=STANDARD_IA \
	--human-readable-sizes \
	--follow-symlinks \
	--no-delete-removed \
	--acl-public \
	--guess-mime-type \
	"${S3CMD_ARGS[@]}" \
	sync \
	"$WORKDIR/content/" \
	"s3://phusion-passenger/binaries/$S3_BUCKET_NAME/by_release/$VERSION/"
