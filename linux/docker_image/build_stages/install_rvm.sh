#!/bin/bash
set -e
source /pbba_build/support/functions.sh
source /hbb/activate_func.sh

activate_holy_build_box_deps_installation_environment

header "Installing RVM"
run gpg --keyserver hkp://keys.gnupg.net --recv-keys 409B6B1796C275462A1703113804BB82D39DC0E3
run curl -L -o /tmp/install-rvm.sh https://get.rvm.io
run bash /tmp/install-rvm.sh stable
