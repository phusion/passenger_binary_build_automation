#!/bin/bash
set -e
source /pbba_build/support/functions.sh
source /hbb/activate_func.sh
RUBY_VERSIONS=(`cat /pbba_build/definitions/ruby_versions`)
LAST_RUBY_VERSION=${RUBY_VERSIONS[${#RUBY_VERSIONS[@]} - 1]}

activate_holy_build_box_deps_installation_environment

for RUBY_VERSION in $RUBY_VERSIONS; do
	header "Installing Ruby $RUBY_VERSION"
	run /usr/local/rvm/bin/rvm install ruby-$RUBY_VERSION
	run /usr/local/rvm/bin/rvm-exec ruby-$RUBY_VERSION gem install bundler drake --no-document
done

echo "+ Setting ruby-$LAST_RUBY_VERSION as default"
bash -lc "rvm --default ruby-$LAST_RUBY_VERSION"

run /usr/local/rvm/bin/rvm-exec ruby-$LAST_RUBY_VERSION gem install drake bluecloth --no-document
run /usr/local/rvm/bin/rvm-exec ruby-$LAST_RUBY_VERSION gem install rspec -v 2.14.1 --no-document

run usermod -aG rvm app
