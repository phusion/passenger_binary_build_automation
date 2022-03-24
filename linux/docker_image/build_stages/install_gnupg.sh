#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh

header "Installing GnuPG"

run_yum_install gnupg2
