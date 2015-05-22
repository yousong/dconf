_sshfs_mount() {
	local name="$1"
	local user="$2"
	local host="$3"
	local port="$4"
	local remotedir="$5"
	local localdir="$6"
	local option="$7"

	[ -z "$user" ] && return 1
	[ -z "$name" ] && return 1
	[ -z "$host" ] && return 1

	port=${port:-22}
	if ! ncs "$host" "$port" >/dev/null 2>&1 ; then
		__errmsg "sshfs: $name: connection to $host:$port failed."
		return 1
	fi

	localdir=${localdir:-~/.sshfs/$name}
	option=${option:-auto_cache,reconnect,defer_permissions,negative_vncache,volname=$name,noappledouble}

	[ -d "$localdir" ] || mkdir -p "$localdir" || {
		__errmsg "sshfs: $name: cannot create local dir: $localdir"
		return
	}

	sshfs -p "$port" "$user@$host:$remotedir" "$localdir" -o "$option"
}

_sshfs_umount() {
	local name="$1"
	local localdir="$6"

	[ -z "$name" ] && return 1

	localdir=${localdir:-~/.sshfs/$name}
	umount "$localdir"
}

_sshfs_action() {
	local action="$1"; shift
	local names="${@:-${_sshfs_profiles}}"
	local profile

	eval set -- $names
	while [ -n "$1" ]; do
		eval profile="\${_sshfs_profile_$1}"
		eval "$action" $profile
		shift
	done
}

sshfs_mount() {
	_sshfs_action _sshfs_mount "$@"
}

sshfs_umount() {
	_sshfs_action _sshfs_umount "$@"
}

# Profile Format
#
#   ProfileName Username Hostname Port RemoteDir LocalDir Options
#
_sshfs_profiles=

# Add a profile local_debian with
#
#    _sshfs_add_profile local_debian yousong 172.16.124.128 22 /home/yousong
#
# Mount it with
#
#    sshfs_mount local_debian
_sshfs_add_profile() {
	local name=$1

	eval export _sshfs_profile_$name=\""$@"\"
	export _sshfs_profiles="$_sshfs_profiles $name"
}

