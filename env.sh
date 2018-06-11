TOPDIR="${TOPDIR:-$PWD}"

o_homedir="${o_homedir:-$HOME}"
DATA_DIR="$TOPDIR/data"
PATCH_DIR="$TOPDIR/patches"
SCRIPT_DIR="$TOPDIR/scripts"

cp --version | grep -q -m1 "GNU coreutils" \
	|| which -s gcp \
	|| {
	# we need echo, cp from coreutils
	#
	# BSD echo in OSX and built-in echo of /bin/sh do not understand -e option
	echo "GNU coreutils is required" >&2
	exit 1
}

alias cp="gcp --no-preserve=all -R -T"

# use the first one in path
o_echo="$(which -a echo | grep -v built-in | head -n1)"
o_aqua="$("$o_echo" -e '\e[1;40;36m')"
o_gelb="$("$o_echo" -e '\e[1;40;33m')"
o_rote="$("$o_echo" -e '\e[1;40;31m')"
o_norm="$("$o_echo" -e '\e[0m')"
__errmsg() {
	"$o_echo" "dconf: $1" >&2
}

__info() {
	__errmsg "${o_aqua}info:${o_norm} $1"
}

__notice() {
	__errmsg "${o_gelb}notice:${o_norm} $1"
}

__error() {
	__errmsg "${o_rote}error:${o_norm} $1"
}

_do() {
	local script="$1"
	local action="$2"

	[ -n "$INCLUDE_ONLY" ] && return 0
	mkdir -p "$DATA_DIR" "$PATCH_DIR" "$SCRIPT_DIR"
	mkdir -p "$o_homedir"

	. "$script"
	if type "$action" 1>/dev/null 2>&1; then
		__info "working on $script"
		"$action"
	else
		__notice "ignore non-defined action: $action"
	fi
}
