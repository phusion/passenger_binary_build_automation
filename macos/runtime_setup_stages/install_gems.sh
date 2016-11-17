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
run env BUNDLE_GEMFILE="$ROOTDIR/shared/Gemfile" /usr/local/bin/bundle install --system -j2

if [[ -e /usr/local/rvm/bin/rvm-exec ]]; then
	RVM_EXEC=/usr/local/rvm/bin/rvm-exec
elif [[ -e $HOME/.rvm/bin/rvm-exec ]]; then
	RVM_EXEC=$HOME/.rvm/bin/rvm-exec
else
	echo "*** ERROR: you must have RVM installed"
	exit 1
fi

header "Checking Ruby versions"
ALL_RUBIES_OK=true
for RUBY_VERSION in "${RUBY_VERSIONS[@]}"; do
	if $RVM_EXEC ruby-$RUBY_VERSION ruby -v &>/dev/null; then
		echo "Ruby $RUBY_VERSION: ok"
	else
		echo "Ruby $RUBY_VERSION: NOT INSTALLED!"
		ALL_RUBIES_OK=false
	fi
done
if ! $ALL_RUBIES_OK; then
	exit 1
fi

header "Installing RVM Ruby gems"
for RUBY_VERSION in "${RUBY_VERSIONS[@]}"; do
	if $RVM_EXEC ruby-$RUBY_VERSION command -v drake &>/dev/null; then
		echo "Ruby $RUBY_VERSION: drake already installed"
	else
		run $RVM_EXEC ruby-$RUBY_VERSION gem install drake --no-document
	fi
done
