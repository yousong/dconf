#!/bin/bash -e

. "$TOPDIR/env.sh"

__uv_conf="$o_homedir/.config/uv/uv.toml"
#
# only use legacy since most of environments I am currently working on only
# recogise it
#
__uv_conf_files="
"

config() {
	local d
	local dataf

	d="${__uv_conf%/*}"
	mkdir -p "$d"

	dataf="$DATA_DIR/${__uv_conf##*/}"
	cp "$dataf" "$__uv_conf"
}

collect() {
	local f dataf

	if [ -f "$__uv_conf" ]; then
		dataf="$DATA_DIR/${__uv_conf##*/}"
		cp "$__uv_conf" "$dataf"
	fi
}
