TOPDIR="${TOPDIR:-$PWD}"

o_os="$(uname -s)"
o_mach="$(uname -m)"
o_homedir="${o_homedir:-$HOME}"
DATA_DIR="$TOPDIR/data"
DATA_PRIVATE_DIR="$TOPDIR/data_private"
PATCH_DIR="$TOPDIR/patches"
SCRIPT_DIR="$TOPDIR/scripts"

if cp --version | grep -q -m1 "GNU coreutils"; then
	cp() {
		command cp --no-preserve=all -R -T "$@"
	}
elif which -s gcp &>/dev/null; then
	cp() {
		command gcp --no-preserve=all -R -T "$@"
	}
else
	# we need echo, cp from coreutils
	#
	# BSD echo in OSX and built-in echo of /bin/sh do not understand -e option
	echo "GNU coreutils is required" >&2
	exit 1
fi

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

__notice_private() {
	__notice "${o_gelb}private data:${o_norm} $*"
}


__error() {
	__errmsg "${o_rote}error:${o_norm} $1"
}

goarch(){
	case "$o_mach" in
		arm64) echo arm64;;
		x86_64) echo amd64;;
		*)
			__error "unknown uname machine $o_mach"
			return 1
			;;
	esac
}

template_eval() {
	local _f="$1"
	local _tmpf
	local _l
	local _out=1
	local _tmpl_sig="##DCONF "

	_tmpf="$(mktemp dconf-XXX)"
	while read _l; do
		case "$_l" in
			"$_tmpl_sig"*)
				expr="${_l#$_tmpl_sig}"
				if [ "$expr" = end ]; then
					_out=1
				elif eval "$expr"; then
					_out=1
				else
					_out=
				fi
				;;
			*)
				if [ -n "$_out" ]; then
					echo "$_l"
				fi
		esac
	done <"$_f" >"$_tmpf"

	mv "$_tmpf" "$_f"
	rm -f "$_tmpf"
}

format_patch() {
	local wokd="$1"; shift
	local outd="$1"; shift
	local rang="$1"; shift

	git \
		--work-tree "$wokd" \
		--git-dir "$wokd/.git" \
		format-patch \
		--output-directory "$outd" \
		--zero-commit \
		"$rang"
}

_do() {
	local script="$1"
	local action="$2"

	[ -n "$INCLUDE_ONLY" ] && return 0
	mkdir -p "$DATA_DIR" "$PATCH_DIR" "$SCRIPT_DIR"
	mkdir -p "$DATA_PRIVATE_DIR"
	mkdir -p "$o_homedir"

	. "$script"
	__info "working on $script"
	if type "$action" 1>/dev/null 2>&1; then
		"$action"
	else
		__notice "ignore: action $action not defined"
	fi
}

__rsync_d() {
	local src="$1"; shift
	local dst="$1"; shift

	if test -d "$src" && test "${src%/}" = "$src"; then
		src="$src/"
	fi
	rsync -aP "$src" "$dst"
}

__config_private_data() {
	local name="$1"; shift
	local app_file="$1"; shift
	local backup_file="$1"; shift

	if ! test -s "$backup_file"; then
		return
	fi
	if ! test -s "$app_file"; then
		return
	fi
	if ! test "$backup_file" -nt "$app_file"; then
		__notice_private "$name: skip as the $backup_file is NOT newer than $app_file"
		return
	fi

	# Known issues
	# - Notes: "Accounts/LocalAccount" does not exist on new macos
	#   installations and as such it will fail the "test -s" check above
	# - Notes: "NoteStore.sqlite". We need to also delete "-shm", "-wal"
	#   files to let the new db file take effect
	#
	#
	# On macos, check the following for permission issues
	# - Full disk access.  System Settings, Privacy & Security, Full disk access
	# - System integration protection.  Reboot into recovery mode (Hold Cmd-R on boot), "csrutil disable"
	if ! __rsync_d "$backup_file" "$app_file"; then
		__notice_private "$name: $app_file: retry with cp"
		cp "$backup_file" "$app_file"
	fi
}

__collect_private_data() {
	local name="$1"; shift
	local app_file="$1"; shift
	local backup_file="$1"; shift
	local app_dir="${app_file%/*}"

	if ! test -d "$app_dir"; then
		return
	fi

	mkdir -p "${backup_file%/*}"
	if ! __rsync_d "$app_file" "$backup_file"; then
		__notice_private "$name: $app_file: retry with cp"
		cp "$app_file" "$backup_file"
	fi
}
