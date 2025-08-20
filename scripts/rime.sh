#!/bin/bash -e

. "$TOPDIR/env.sh"

rime_dir() {
	case "$o_os" in
		Darwin) echo "$HOME/Library/Rime" ;;
		Linux) echo "$HOME/.config/ibus/rime" ;;
	esac
}

rime_cp_custom_yaml() {
	local src="$1"; shift
	local dst="$1"; shift

	if [ "$src" = "$DATA_DIR" ]; then
		find "$src" -maxdepth 1 -name "_rime.*.custom.yaml" -type f \
			| while read srcf; do
				dstf="$(basename "$srcf")"
				dstf="${dstf#_rime.}"
				cp "$srcf" "$dst/$dstf"
			done
	else
		find "$src" -maxdepth 1 -name "*.custom.yaml" -type f \
			| while read srcf; do
				dstf="$(basename "$srcf")"
				dstf="_rime.$dstf"
				cp "$srcf" "$dst/$dstf"
			done
	fi
}

config() {
	local rd="$(rime_dir)"

	if [ -d "$rd" ]; then
		if [ ! -d "$rd/rime-wubi" ]; then
			git clone https://github.com/rime/rime-wubi.git "$rd/rime-wubi"
		fi

		find "$rd" -maxdepth 1 -type l | xargs rm -vf
		ln -sf rime-wubi/wubi86.dict.yaml "$rd/wubi86.dict.yaml"
		ln -sf rime-wubi/wubi86.schema.yaml "$rd/wubi86.schema.yaml"

		find "$rd" -maxdepth 1 -type f -name '*.custom.yaml' | xargs rm -vf
		rime_cp_custom_yaml "$DATA_DIR" "$rd"
	fi
}

collect() {
	local rd="$(rime_dir)"

	if [ -s "$rd/default.custom.yaml" ]; then
		rime_cp_custom_yaml "$rd" "$DATA_DIR"
	fi
}

config_private_data() {
	local rd="$(rime_dir)"
	local rdp="$DATA_PRIVATE_DIR/rime"
	local userdb_files f

	if ! test -d "$rd"; then
		return
	fi
	if ! test -d "$rdp"; then
		return
	fi
	userdb_files="$(find "$rdp" -name "*.userdb.txt")"
	for f in $userdb_files; do
		cp "$f" "$rd/${f##*/}"
	done

	__notice_private 'rime: click "Deploy" to apply userdb config'
}

collect_private_data() {
	local rd="$(rime_dir)"
	local syncdir="$rd/sync"
	local userdb_files f

	if ! test -d "$rd"; then
		return
	fi

	__notice_private 'rime: click "Sync user data" to save private data'
	if ! test -d "$syncdir"; then
		return
	fi

	userdb_files="$(find "$syncdir" -name "*.userdb.txt")"
	mkdir -p "$DATA_PRIVATE_DIR/rime"
	for f in $userdb_files; do
		cp "$f" "$DATA_PRIVATE_DIR/rime/${f##*/}"
	done
}
