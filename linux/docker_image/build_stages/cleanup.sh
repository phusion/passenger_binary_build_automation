#!/bin/bash
set -e
source /pbba_build/support/functions.sh

header "Cleaning up"
run yum clean -y all
run /usr/local/rvm/bin/rvm cleanup all
run rm -rf /pbba_build /tmp/*
run rm -rf /hbb/share/doc /hbb/share/man
