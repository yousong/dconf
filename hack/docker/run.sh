#!/usr/bin/env bash

set -o errexit
set -o pipefail

# get id from part of the form id(name)
partGetId() {
	local part="$1"; shift

	part="${part%%(*}"
	echo "$part"
}

# get id from part of the form id(name)
partGetName() {
	local part="$1"; shift

	part="${part##*(}"
	part="${part%%)*}"
	echo "$part"
}

# trim out chr from value of var starting from left
ltrim() {
	local var="$1"; shift
	local chr="$1"; shift
	local t

	eval t="\$$var"
	while [ "${t#$chr}" != "$t" ]; do
		t="${t#$chr}"
	done
	eval "$var=\$t"
}


# init variables like id_uid, id_gid, id_groups from output of id command
init_id_x() {
	local id_id="$1"; shift
	local x

	for part in $id_id; do
		case "$part" in
			uid=*|gid=*|groups=*)
				x="${part#*=}"
				eval "id_${part%%=*}=\$x"
				;;
		esac
	done
}

logDo() {
	echo "dconf: $*" >&2
	"$@"
}

# prepareDir mkdir -p "$pfx/$rem" and chown each newly-made dir component to
# that of "$pfx"
prepareDir() {
	local pfx="$1"; shift
	local rem="$1"; shift
	local owner
	local base

	[ -d "$pfx" ]
	owner="$(stat --format %u:%g "$pfx")"
	while [ -n "$rem" ]; do
		base="${rem%%/*}"
		if [ "${rem#*/}" != "$rem" ]; then
			rem="${rem#*/}"
		else
			rem=
		fi
		if [ -n "$base" ]; then
			pfx="$pfx/$base"
			if ! [ -d "$pfx" ]; then
				mkdir -p "$pfx"
				chown "$owner" "$pfx"
			fi
		fi
	done
}

moveMounts() {
	local oldpfx="$1"; shift
	local newpfx="$1"; shift
	local dst
	local rem

	while read _ dst _; do
		rem="${dst#$oldpfx}"
		if [ "$rem" != "$dst" ]; then
			ltrim rem /
			prepareDir "$newpfx" "$rem"
			logDo mount --move "$dst" "$newpfx/$rem"
		fi
	done </proc/mounts
}

# default cmd for entrypoint inside container
#
#  - Try to match uid, gid, supplementary gids with info passed via "$id_id"
#  - su to that user
entrypoint() {
	local ousr=abc
	local ouid
	local ogid
	local susr="$ousr"

	local id_uid id_gid id_groups
	init_id_x "$id_id"

	# This is for starting a stopped container.  E.g. docker start -ai
	if ! id -u "$ousr" &>/dev/null; then
		if [ -n "$id_uid" ]; then
			susr="$(partGetName "$id_uid")"
			moveMounts "/home/$ousr" "/home/$susr"
			logDo exec su - "$susr"
		fi
	fi

	local args=()
	ouid="$(id -u "$ousr")"
	ogid="$(id -g "$ousr")"

	if [ -n "$id_uid" ]; then
		local nusr nuid

		nuid="$(partGetId "$id_uid")"
		nusr="$(partGetName "$id_uid")"
		if [ -n "$nuid" -a "$nuid" != "$ouid" ]; then
			# change UID
			args+=( --uid "$nuid" )
		fi
		if [ -n "$nusr" -a "$nusr" != "$ousr" ]; then
			# change username if
			#  - it differs from current name
			#  - the name does not exist yet
			if ! grep -q -m1 "^$nusr:" /etc/passwd; then
				args+=(
					--login "$nusr"
					--home "/home/$nusr"
					--move-home
				)
				susr="$nusr"
			fi
		fi
	fi

	if [ -n "$id_gid" ]; then
		local ngid

		ngid="$(partGetId "$id_gid")"
		if [ -n "$ngid" -a "$ngid" != "$ogid" ] ; then
			# change UID
			args+=( --gid "$ngid" )
		fi
	fi

	if [ -n "$id_groups" ]; then
		local ogroups
		local npart
		local groupsArg

		ogroups=",$(id "$ousr" | grep -oE 'groups=[^ ]+' | cut -d= -f2)"
		for npart in ${id_groups//,/ }; do
			local Gid

			# append to supplementary groups new gids if
			#  - the gid is not present in supplementary groups yet
			Gid="$(partGetId "$npart")"
			if [ "${ogroups/,$Gid\(/}" = "$ogroups" ]; then
				# create a new grp if the Gid is not present yet
				if ! cut -d: -f3 /etc/group | grep -q -m1 "^$Gid$"; then
					local Grp

					# prefix Grp with underscore to avoid
					# name collision
					Grp="$(partGetName "$npart")"
					while grep -q -m1 "^$Grp:" /etc/group; do
						Grp="_$Grp"
					done
					logDo groupadd --gid "$Gid" "$Grp"
				fi
				groupsArg="$groupsArg,$Gid"
			fi
		done
		if [ -n "$groupsArg" ]; then
			groupsArg="${groupsArg#,}"
			args+=(
				--groups "$groupsArg"
				--append
			)
		fi
	fi

	if [ "${#args[@]}" -gt 0 ]; then
		local mnts
		mnts="$(mktemp --directory /tmp/dconf.XXX)"
		moveMounts "/home/$ousr" "$mnts"
		logDo usermod "${args[@]}" "$ousr"
		moveMounts "$mnts" "/home/$nusr"
		find "$mnts" -depth -print0 | xargs -r -0 rmdir
		if [ "$ousr" != "$susr" -a -f "/etc/sudoers.d/$ousr" ]; then
			logDo sed -i -e "s/^$ousr /$nusr /" "/etc/sudoers.d/$ousr"
			logDo mv "/etc/sudoers.d/$ousr" "/etc/sudoers.d/${nusr//./_}"
		fi
	fi

	logDo exec su - "$susr"
}

# a command for entrypoint for any command therein
run() {
	exec "$@"
}

# start a container
docker() {
	local part

	# --interactive
	# --name
	# --volume
	command docker run \
		--privileged \
		--pid=host \
		--network=host \
		--tty \
		--env "id_id=$(id)" \
		"$@" \
		yousong/dconf
}

"$@"
