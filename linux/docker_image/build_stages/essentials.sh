#!/bin/bash
set -e
source /pbba_build/support/functions.sh

header "Installing essentials"
run_yum_install gpg
run groupadd -g 2457 app
run adduser --uid 2457 --gid 2457 app
