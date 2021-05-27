#!/bin/bash
set -e
source /pbba_build/shared/lib/library.sh

header "Installing essentials"
run_yum_install pth-devel ncurses-devel xz
