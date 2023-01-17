#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate
RUBY_VERSIONS=(`cat /pbba_build/shared/definitions/ruby_versions`)
LAST_RUBY_VERSION=${RUBY_VERSIONS[${#RUBY_VERSIONS[@]} - 1]}
RUBYGEMS_VERSION=$(cat /pbba_build/shared/definitions/rubygems_version)

for RUBY_VERSION in "${RUBY_VERSIONS[@]}"; do
	header "Installing Ruby $RUBY_VERSION"
	run /usr/local/rvm/bin/rvm install ruby-$RUBY_VERSION --rubygems $RUBYGEMS_VERSION || { tail -n +1 /usr/local/rvm/log/*_ruby-"$RUBY_VERSION"*/*.log /usr/local/rvm/src/ruby-"$RUBY_VERSION"/ext/*/mkmf.log && false; };
	run /usr/local/rvm/bin/rvm-exec ruby-$RUBY_VERSION gem install rake --no-document
	run /usr/local/rvm/bin/rvm-exec ruby-$RUBY_VERSION gem install bundler --no-document
	run strip --strip-all /usr/local/rvm/rubies/ruby-$RUBY_VERSION*/bin/ruby
	run strip --strip-debug /usr/local/rvm/rubies/ruby-$RUBY_VERSION*/lib/libruby.so
	run rm -f /usr/local/rvm/rubies/ruby-$RUBY_VERSION*/lib/libruby-static.a
done

echo "+ Setting ruby-$LAST_RUBY_VERSION as default"
bash -lc "rvm --default ruby-$LAST_RUBY_VERSION"

run /usr/local/rvm/bin/rvm-exec ruby-$LAST_RUBY_VERSION \
	env BUNDLE_GEMFILE=/pbba_build/shared/Gemfile \
	bundle install -j 2

run usermod -aG rvm builder
