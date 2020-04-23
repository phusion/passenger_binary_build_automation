#!/bin/bash
set -e
ROOTDIR=$(dirname "$0")
ROOTDIR=$(cd "$ROOTDIR/../.." && pwd)
source "$ROOTDIR/shared/lib/library.sh"

RUBY_VERSIONS=($(cat "$ROOTDIR/shared/definitions/ruby_versions"))
LAST_RUBY_VERSION=${RUBY_VERSIONS[${#RUBY_VERSIONS[@]} - 1]}

if [[ -e /usr/local/rvm/bin/rvm-exec ]]; then
	RVM_EXEC=/usr/local/rvm/bin/rvm-exec
elif [[ -e $HOME/.rvm/bin/rvm-exec ]]; then
	RVM_EXEC=$HOME/.rvm/bin/rvm-exec
else
	echo "*** ERROR: you must have RVM installed"
	exit 1
fi

function run_ruby() {
	VERSION=$1
	shift
	"$RVM_EXEC" "ruby-$VERSION" "$@"
}

header "Checking Ruby versions"
ALL_RUBIES_OK=true
for RUBY_VERSION in "${RUBY_VERSIONS[@]}"; do
	if run_ruby "$RUBY_VERSION" ruby -v &>/dev/null; then
		echo "Ruby $RUBY_VERSION: ok"
	else
		echo "Ruby $RUBY_VERSION: NOT INSTALLED! Please install it!"
		ALL_RUBIES_OK=false
	fi
done

if ! $ALL_RUBIES_OK; then
	exit 1
fi

header "Installing gem bundle"
echo "+ Installing Bundler version from Gemfile.lock"
run_ruby "$LAST_RUBY_VERSION" gem install bundler -v $(fgrep -A1 'BUNDLED WITH' "$ROOTDIR/shared/Gemfile.lock" | tail -n 1) --no-document

# Copy over the Gemfile to prevent creating a .bundle directory in shared/.
run cp "$ROOTDIR/shared/Gemfile" "$ROOTDIR/shared/Gemfile.lock" "$WORKDIR/"
echo "+ Installing gem bundle into $RUNTIME_DIR/gems/$LAST_RUBY_VERSION"
run_ruby "$LAST_RUBY_VERSION" \
	env BUNDLE_GEMFILE="$WORKDIR/Gemfile" \
	BUNDLE_PATH="$RUNTIME_DIR/gems/$LAST_RUBY_VERSION" \
	"$RUNTIME_DIR/gems/$LAST_RUBY_VERSION/bin/bundle" install -j2
