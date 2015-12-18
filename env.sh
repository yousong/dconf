TOPDIR="${TOPDIR:-$PWD}"

DATA_DIR="$TOPDIR/data"
PATCH_DIR="$TOPDIR/patches"
SCRIPT_DIR="$TOPDIR/scripts"

alias cp="cp --no-preserve=all -R -T"

__errmsg() {
	echo "dconf: $1" >&2
}

_do() {
	local script="$1"
	local action="$2"

	[ -n "$INCLUDE_ONLY" ] && return 0
	mkdir -p "$DATA_DIR" "$PATCH_DIR" "$SCRIPT_DIR"

	__errmsg "working on $script"
	. "$script"
	if type "$action" 1>/dev/null 2>&1; then
		"$action"
	else
		__errmsg "ignore non-defined action: $action"
	fi
}
