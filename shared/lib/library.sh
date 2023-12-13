#!/usr/bin/env bash
set -e

RESET=$(echo -e "\\033[0m")
BOLD=$(echo -e "\\033[1m")
YELLOW=$(echo -e "\\033[33m")
BLUE_BG=$(echo -e "\\033[44m")

function header()
{
	local title="$1"
	echo
	echo "${BLUE_BG}${YELLOW}${BOLD}${title}${RESET}"
	echo "------------------------------------------"
}

function run()
{
	echo "+ $*"
	"$@"
}

function run_exec()
{
	echo "+ $*"
	exec "$@"
}

function absolute_path()
{
	local dir
	local name

	dir=$(dirname "$1")
	name=$(basename "$1")
	dir=$(cd "$dir" && pwd)
	echo "$dir/$name"
}

function run_yum_install()
{
	run yum install -y "$@"
}

function require_args_exact()
{
	local count="$1"
	shift
	if [[ $# -ne $count ]]; then
		echo "ERROR: $count arguments expected, but got $#."
		exit 1
	fi
}

function require_envvar()
{
	local name="$1"
	local value="$2"
	if [[ "$value" = "" ]]; then
		echo "ERROR: the environment variable '$name' is required."
		exit 1
	fi
}

function download_and_extract()
{
	local BASENAME="$1"
	local DIRNAME="$2"
	local URL="$3"
	local bz2_regex='\.bz2$'
	local xz_regex='\.xz$'

	local DOWNLOAD_DIR
	if [[ "$WORKDIR" != '' ]]; then
		DOWNLOAD_DIR="$WORKDIR"
	else
		DOWNLOAD_DIR=/tmp
	fi

	if [[ ! -e "$DOWNLOAD_DIR/$BASENAME" ]]; then
		run rm -f "$DOWNLOAD_DIR/$BASENAME.tmp"
		run curl --fail -L -o "$DOWNLOAD_DIR/$BASENAME.tmp" "$URL"
		run mv "$DOWNLOAD_DIR/$BASENAME.tmp" "$DOWNLOAD_DIR/$BASENAME"
	fi
	if [[ "$URL" =~ $bz2_regex ]]; then
		run tar xjf "$DOWNLOAD_DIR/$BASENAME"
	elif [[ "$URL" =~ $xz_regex ]]; then
		run tar xJf "$DOWNLOAD_DIR/$BASENAME"
	else
		run tar xzf "$DOWNLOAD_DIR/$BASENAME"
	fi

	echo "Entering $RUNTIME_DIR/$DIRNAME"
	pushd "$DIRNAME" >/dev/null
}

function check_macos_runtime_compatibility()
{
	local RUNTIME_DIR="$1"
	local VERSION="$2"

	if [[ -e "$RUNTIME_DIR/MACOS_RUNTIME_VERSION" ]]; then
		ACTUAL_VERSION=$(cat "$RUNTIME_DIR/MACOS_RUNTIME_VERSION")
		if [[ "$VERSION" != "$ACTUAL_VERSION" ]]; then
			echo "ERROR: $RUNTIME_DIR has version number $ACTUAL_VERSION," \
			     "but version $VERSION expected. Please rebuild the runtime directory."
			return 1
		fi
	else
		echo "ERROR: $RUNTIME_DIR is unversioned. Please rebuild it."
		return 1
	fi
}

function _cleanup()
{
	set +e
	local pids
	pids=$(jobs -p)
	if [[ "$pids" != "" ]]; then
		# shellcheck disable=SC2086
		kill $pids 2>/dev/null
	fi
	if [[ $(type -t cleanup) == function ]]; then
		cleanup
	fi
}

function vergte() {
	echo -e "$1\n$2" | sort -rCV
}

trap _cleanup EXIT
