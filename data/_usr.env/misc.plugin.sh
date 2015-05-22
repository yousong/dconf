path_prepend() {
	local var="$1"
	local new="$2"
	local orig=$(eval echo \$$var)
	local pathes

	pathes="$new"
	eval set -- ${orig//:/ }
	while [ -n "$1" ]; do
		[ "$1" != "$new" ] && pathes="$pathes:$1"
		shift
	done
	eval export $var=\"$pathes\"
}

# netcat scan
function ncs() {
	local host="$1"
	local port="$2"
	local waitopt

	case "$(uname -s)" in
		Darwin) waitopt="-G 1" ;;
		Linux) waitopt="-w 1" ;;
	esac
	nc $waitopt -vz "$host" "$port"
}

function lc() {
	# Note that this is for OpenWrt.
	# directories like ./bin will not be searched by default.
	pattern="$1"
	search_root="${2:-$(pwd)}"
	find -P "$search_root" \( \
			-path "$(pwd)/build_dir" \
		-o -path "$(pwd)/bin" \
		-o -path "$(pwd)/dl" \
		-o -path "$(pwd)/tmp" \
		-o -path "$(pwd)/staging_dir" \
		-o -path "$(pwd)/feeds" \
		-o -path "$(pwd)/docs" \
		-o \( -type d -and -path "$(pwd)/.*/.*" \) \
		\) -prune \
		-o \( \
			-type f \
		\) -print0 \
	| xargs -0 grep --color=auto -n -e "$pattern"
}

init_virtualenv() {
	local cwd="$(pwd)"

	while true; do
		local f="$cwd/bin/activate"
		[ -r "$f" ] && source "$f" && return
		[ "$cwd" = "/" ] && {
			__errmsg "At / now, cannot find bin/activate."
			return
		}
		cwd="$(dirname "$cwd")"
	done
}

rm_ssh_known_hosts() {
	local ln="$1"		# line number

	[ -n "$ln" -a "$ln" -gt 1 ] 2>/dev/null || {
		__errmsg "invalid line number${ln:+: $ln}."
		return 1
	}

	sed -i -e "${ln}d" "$HOME/.ssh/known_hosts"
}

