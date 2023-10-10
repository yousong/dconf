#!/bin/bash -e

. "$TOPDIR/env.sh"

__pip_conf="$o_homedir/.config/pip/pip.conf"
__pip_conf_legacy="$o_homedir/.pip/pip.conf"
__pip_conf_macosx="$o_homedir/Library/Application Support/pip/pip.conf"
#
# only use legacy since most of environments I am currently working on only
# recogise it
#
__pip_conf_files="
	$__pip_conf_legacy
"

config() {
	local f dataf

	for f in $__pip_conf_files; do
		dataf="${f##$o_homedir/.}"
		dataf="$DATA_DIR/_$dataf"
		if [ -f "$dataf" ]; then
			mkdir -p "$(dirname "$f")"
			cp "$dataf" "$f"
		fi
	done
}

collect() {
	local f dataf

	for f in $__pip_conf_files; do
		if [ -f "$f" ]; then
			dataf="${f##$o_homedir/.}"
			dataf="$DATA_DIR/_$dataf"
			mkdir -p "$(dirname "$dataf")"
			cp "$f" "$dataf"
		fi
	done
}
