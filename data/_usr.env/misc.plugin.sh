path_prepend() {
	local var="$1"
	local new="$2"
	local act="$3"
	local orig=$(eval echo \$$var)
	local pathes p

	pathes="$new"
	eval set -- ${orig//:/ }
	# strip out ending slashes for each element in "$@"
	eval set -- ${@%//}
	eval set -- ${@%/}
	while [ -n "$1" ]; do
		p="$1"
		if [ "$p" != "$new" ]; then
			pathes="$pathes:$p"
		elif [ "$act" = "peek" ]; then
			# if it's alreay there, then just return without tampering its
			# current location
			return
		fi
		shift
	done
	eval export $var=\"$pathes\"
}

path_ignore_match() {
	local var="$1"
	local func="$2"
	local orig=$(eval echo \$$var)
	local pathes p

	eval set -- ${orig//:/ }
	# strip out ending slashes for each element in "$@"
	eval set -- ${@%//}
	eval set -- ${@%/}
	while [ -n "$1" ]; do
		p="$1"
		if ! eval "$func $p"; then
			pathes="$pathes:$p"
		fi
		shift
	done
	pathes="${pathes#:}"
	eval export $var=\"$pathes\"
}

# netcat scan
ncs() {
	local host="$1"
	local port="$2"
	local waitopt

	case "$(uname -s)" in
		Darwin) waitopt="-G 1" ;;
		Linux) waitopt="-w 1" ;;
	esac
	nc $waitopt -vz "$host" "$port"
}

lc() {
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

# perror can be provided mysql-server
# here is a poor mans version
if ! which perror &>/dev/null; then
	perror() {
		local errno="$1"

		if [ "$#" -lt 1 ]; then
			__errmsg "Usage: perror <errno>"
			return 1
		fi
		if [ "$errno" -lt 0 ]; then
			errno="$((-1 * $errno))"
		fi
		python -c 'import os; print os.strerror('$errno')'
	}
fi

gitproxy() {
		local action="$1"
		local comm="$GITPROXY_COMM"
		local user="$GITPROXY_USER"
		local host="$GITPROXY_HOST"
		local port="$GITPROXY_PORT"
		local dport="$GITPROXY_DPORT"
		local pid

		# lsof can do, but it's not built-in in several distros.  E.g. show
		# only PID of the process occupying IPv4 TCP port 7001
		#
		#	 lsof -i 4TCP:7001 -t
		pid=$(netstat -4lntp 2>/dev/null | awk '$4 ~ /.*:7001$/ { v=$NF; sub("/.*","",v); print v }')
		case "$action" in
			close)
				unset GIT_PROXY_COMMAND;
				if [ -z "$pid" ]; then
					__errmsg "no gitproxy was running"
					return
				fi
				kill "$pid" && __errmsg "gitproxy (PID: $pid) has been closed"
				return
				;;
			status)
				if [ -z "$pid" ]; then
					__errmsg "gitproxy is not running"
					return
				fi
				__errmsg "gitproxy is running"
				return
				;;
			*)
				if [ -n "$pid" ]; then
					export GIT_PROXY_COMMAND="$comm"
					return
				fi

				ssh -nNTf -D "$dport" -p "$port" "$user@$host"
				pid=$(netstat -4lntp 2>/dev/null | awk '$4 ~ /.*:7001$/ { v=$NF; sub("/.*","",v); print v }')
				if [ -z "$pid" ]; then
					__errmsg "open gitproxy failed"
					return
				fi
				export GIT_PROXY_COMMAND="$comm"
		esac
}

qa_python() {
	if [ "$#" -lt 1 ]; then
		__errmsg "Usage: $0 <project_path_or_python_filename>"
		return 1;
	fi

	if [ -z "$FLAKE8" ]; then
		if ! which flake8 >/dev/null; then
			__errmsg "Please install flake8 with pip"
			return 1
		fi
		FLAKE8="$(which flake8)"
	fi

	# Warning/Error codes, https://flake8.readthedocs.org/en/latest/warnings.html
	$FLAKE8 --ignore=E501,E272,E221,E225,E303,W601,E302,E502,W291,E261,E262,W391,E127,E128,E126,E123,E125,E124,E711,E712,E121,E111,E265,E131,E226,E241 "$1"
}
