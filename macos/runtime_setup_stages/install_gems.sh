#!/bin/bash
set -e
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

RUBY_VERSIONS=(`cat "$ROOTDIR/shared/definitions/ruby_versions"`)

header "Installing system Ruby gems"
if [[ ! -e /usr/local/bin/bundle ]]; then
	run sudo gem install bundler --no-document
fi

# Copy over the Gemfile to prevent creating a .bundle directory in shared/.
run cp "$ROOTDIR/shared/Gemfile" "$ROOTDIR/shared/Gemfile.lock" "$WORKDIR"
run env BUNDLE_GEMFILE="$WORKDIR/Gemfile" /usr/local/bin/bundle install --system -j2

if [[ -e /usr/local/rvm/bin/rvm-exec ]]; then
	RVM_EXEC=/usr/local/rvm/bin/rvm-exec
	RVM_GEMS_DIR=/usr/local/rvm/gems
elif [[ -e $HOME/.rvm/bin/rvm-exec ]]; then
	RVM_EXEC=$HOME/.rvm/bin/rvm-exec
	RVM_GEMS_DIR=$HOME/.rvm/gems
else
	echo "*** ERROR: you must have RVM installed"
	exit 1
fi

function run_ruby() {
	VERSION=$1
	shift
	COMMAND=$1
	shift
	$RVM_EXEC "ruby-$VERSION" $COMMAND "$@"
}

function check_gem() {
	if [[ -f $RVM_GEMS_DIR/ruby-$1/bin/$2 ]]; then
		return 0
	else
		return 1
	fi
}

header "Checking Ruby versions"
ALL_RUBIES_OK=true
for RUBY_VERSION in "${RUBY_VERSIONS[@]}"; do
	if run_ruby $RUBY_VERSION ruby -v &>/dev/null; then
		echo "Ruby $RUBY_VERSION: ok"
	else
		echo "Ruby $RUBY_VERSION: NOT INSTALLED! Please install it!"
		ALL_RUBIES_OK=false
	fi
done

if ! $ALL_RUBIES_OK; then
	exit 1
fi

header "Installing Ruby gems"
for RUBY_VERSION in "${RUBY_VERSIONS[@]}"; do
	if check_gem $RUBY_VERSION drake ; then
		echo "Ruby $RUBY_VERSION: drake already installed"
	else
		run run_ruby $RUBY_VERSION gem install drake --no-document
	fi
done
