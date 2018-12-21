#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh
source /hbb/activate

header "Installing RVM"
run gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3 7D2BAF1CF37B13E2069D6956105BD0E739499BDB
run curl -L -o /tmp/install-rvm.sh https://get.rvm.io
run bash /tmp/install-rvm.sh stable
run /usr/local/rvm/bin/rvm autolibs disable
