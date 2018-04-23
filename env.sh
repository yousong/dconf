TOPDIR="${TOPDIR:-$PWD}"

o_homedir="${o_homedir:-$HOME}"
DATA_DIR="$TOPDIR/data"
PATCH_DIR="$TOPDIR/patches"
SCRIPT_DIR="$TOPDIR/scripts"

alias cp="cp --no-preserve=all -R -T"

# we need echo from coreutils;  BSD echo in OSX and built-in echo of /bin/sh do
# not understand -e option
echo() {
	command echo "$@"
}
o_aqua="$(echo -e '\e[1;40;36m')"
o_gelb="$(echo -e '\e[1;40;33m')"
o_rote="$(echo -e '\e[1;40;31m')"
o_norm="$(echo -e '\e[0m')"
__errmsg() {
	echo "dconf: $1" >&2
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
