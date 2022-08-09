#!/bin/sh -e

. "$TOPDIR/env.sh"

config() {
	local v

	cp "$DATA_DIR/_terraformrc" "$o_homedir/.terraformrc"
}

collect() {
	if [ -f "$o_homedir/.terraformrc" ]; then
		cp "$o_homedir/.terraformrc" "$DATA_DIR/_terraformrc"
	fi
}
