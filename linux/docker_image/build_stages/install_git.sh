#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh

header "Installing Git"

run_yum_install git
