path_prepend() {
	local var="$1"
	local new="$2"
	local act="$3"
	local orig=$(eval echo \$$var)
	local pathes p

	pathes="$new"
	eval set -- ${orig//:/ }
	while [ -n "$1" ]; do
		p="$(echo "$1" | sed 's:/\+$::')"
		if [ "$p" != "$new" ]; then
			pathes="$pathes:$p"
		else
			[ "$act" = "peek" ] && return
		fi
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

# Remove a line from $HOME/.ssh/known_hosts
#
#  - Use "ssh-keygen -R example.com" if the hostname is known
#  - Use "ssh-keygen -F 172.30.32.1" to see if the hostname is there
#  - Use "ssh-keygen -l -f ~/.ssh/known_hosts" to list the file content
#  - Use option "HashKnownHosts no" to disable hashing the content
rm_ssh_known_hosts() {
	local ln="$1"		# line number

	[ -n "$ln" -a "$ln" -ge 1 ] 2>/dev/null || {
		__errmsg "invalid line number${ln:+: $ln}."
		return 1
	}

	sed -i -e "${ln}d" "$HOME/.ssh/known_hosts"
}

