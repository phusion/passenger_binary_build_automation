#!/bin/bash
set -e

/pbba_build/build_stages/essentials.sh
/pbba_build/build_stages/install_rvm.sh
/pbba_build/build_stages/install_ruby.sh
/pbba_build/build_stages/cleanup.sh
