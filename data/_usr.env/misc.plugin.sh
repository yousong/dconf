# test
#
# unset n
# path_action n append v0; echo $n
# path_action n prepend v1; echo $n
# path_action n peek_prepend v2; echo $n
# path_action n peek_append v3; echo $n
#
path_action() {
	local var="$1"
	local action="${2}"
	local new="$3"
	local orig="$(eval echo "\$$var")"
	local peek found
	local pathes p

	case "$action" in
		peek_*)
			action="${action#*_}"
			peek=1
			;;
	esac
	eval set -- ${orig//:/ }
	# strip out ending slashes for each element in "$@"
	eval set -- ${@%//}
	eval set -- ${@%/}
	while [ -n "$1" ]; do
		p="$1"
		if [ "$p" != "$new" -o -n "$peek" ]; then
			pathes="$pathes:$p"
		fi
		if [ "$p" = "$new" ]; then
			found=1
		fi
		shift
	done
	pathes="${pathes#:}"
	if [ -z "$peek" -o -z "$found" ]; then
		case "$action" in
			prepend) pathes="$new:$pathes" ;;
			append) pathes="$pathes:$new" ;;
		esac
	fi
	pathes="${pathes#:}"
	pathes="${pathes%:}"
	eval "export $var=\"$pathes\""
}

path_ignore_match() {
	local var="$1"; shift
	local cb
	local orig=$(eval echo \$$var)
	local pathes p

	cb=("$@") # this cannot sit with the local decl
	eval set -- ${orig//:/ }
	# strip out ending slashes for each element in "$@"
	eval set -- ${@%//}
	eval set -- ${@%/}
	while [ -n "$1" ]; do
		p="$1"
		if ! eval "${cb[@]}" "$p"; then
			pathes="$pathes:$p"
		fi
		shift
	done
	pathes="${pathes#:}"
	eval "export $var=\"$pathes\""
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

virtualenv_activate() {
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
		python3 -c 'import os; print(os.strerror('$errno'))'
	}
fi

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
	$FLAKE8 --ignore=E501,E272,E221,E225,E303,W601,E302,E502,W291,E261,E262,W391,E127,E128,E126,E123,E125,E124,E711,E712,E121,E111,E265,E131,E226,E241,E701,D105 "$1"
}

pkgprovides() {
	local f="$1"

	if [ "${f##*/}" = "$f" ]; then
		f="$(which --skip-alias --skip-functions "$f")"
	fi
	if [ -z "$f" ]; then
		__errmsg "empty arg0"
		return 1
	fi

	if command -v rpm 2>&1 >/dev/null; then
		rpm -qf "$f"
	elif command -v dpkg 2>&1 >/dev/null; then
		dpkg --search "$f"
	elif command -v apk 2>&1 >/dev/null; then
		apk info --who-owns "$f"
	else
		__errmsg "cannot determin package manager"
	fi
}

gpg_prep() {
	local old
	local cur
	local pid

	cur="$(tty 2>/dev/null)"
	if [ -z "$cur" ]; then
		__errmsg "cannot find current tty"
		return 1
	fi
	pid="$(pgrep gpg-agent 2>/dev/null)"
	if [ -n "$pid" ]; then
		old="$(grep -oE --null-data '^GPG_TTY=[[:print:]]+' "/proc/$pid/environ" | cut -f2 -d=)"
		if [ "$old" != "$cur" ]; then
			__errmsg "gpg-agent($pid) is running with GPG_TTY=$old"
			return 1
		fi
		return 0
	fi
	# To load passphrase-protected secret keys, gpg-agent invokes pinentry on
	# $GPG_TTY to prompt for passphrase.  It's local to gpg-agent.
	export GPG_TTY="$(tty 2>/dev/null)"
}

# prepend timestamps to cmd stdout
tsit() {
	local l

	"$@" | while read l; do
		echo "$(date) | $l"
	done
}
