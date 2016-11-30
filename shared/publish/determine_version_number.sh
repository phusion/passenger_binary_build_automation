#!/bin/bash

set -e
set -o pipefail
ROOTDIR=`dirname "$0"`
ROOTDIR=`cd "$ROOTDIR/../.." && pwd`
source "$ROOTDIR/shared/lib/library.sh"

require_envvar PASSENGER_ROOT "$PASSENGER_ROOT"

grep ' VERSION_STRING = ' "$PASSENGER_ROOT/src/ruby_supportlib/phusion_passenger.rb" | awk -F "'" '{ print $2 }'
