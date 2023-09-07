#!/bin/sh -e

. "$TOPDIR/env.sh"

config() {
	local v

	cp "$DATA_DIR/_condarc" "$o_homedir/.condarc"
}

collect() {
	if [ -f "$o_homedir/.condarc" ]; then
		cp "$o_homedir/.condarc" "$DATA_DIR/_condarc"
	fi
}
