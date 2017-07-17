if perl -v >/dev/null 2>/dev/null; then
	RESET=`perl -e 'print("\e[0m")'`
	BOLD=`perl -e 'print("\e[1m")'`
	YELLOW=`perl -e 'print("\e[33m")'`
	BLUE_BG=`perl -e 'print("\e[44m")'`
elif python -V >/dev/null 2>/dev/null; then
	RESET=`echo 'import sys; sys.stdout.write("\033[0m")' | python`
	BOLD=`echo 'import sys; sys.stdout.write("\033[1m")' | python`
	YELLOW=`echo 'import sys; sys.stdout.write("\033[33m")' | python`
	BLUE_BG=`echo 'import sys; sys.stdout.write("\033[44m")' | python`
else
	RESET=
	BOLD=
	YELLOW=
	BLUE_BG=
fi

function header()
{
	local title="$1"
	echo
	echo "${BLUE_BG}${YELLOW}${BOLD}${title}${RESET}"
	echo "------------------------------------------"
}

function run()
{
	echo "+ $@"
	"$@"
}

function run_exec()
{
	echo "+ $@"
	exec "$@"
}

function absolute_path()
{
	local dir="`dirname \"$1\"`"
	local name="`basename \"$1\"`"
	dir="`cd \"$dir\" && pwd`"
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
	local regex='\.bz2$'

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
	if [[ "$URL" =~ $regex ]]; then
		run tar xjf "$DOWNLOAD_DIR/$BASENAME"
	else
		run tar xzf "$DOWNLOAD_DIR/$BASENAME"
	fi

	echo "Entering $RUNTIME_DIR/$DIRNAME"
	pushd "$DIRNAME" >/dev/null
}

function _cleanup()
{
	set +e

	local PIDS=`jobs -p`
	if [[ "$PIDS" != "" ]]; then
		kill $PIDS
	fi

	local t=`type -t cleanup`
	if [[ "$t" = 'function' ]]; then
		cleanup
	fi
}

trap _cleanup EXIT
