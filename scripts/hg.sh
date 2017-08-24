#!/bin/sh -e

. "$TOPDIR/env.sh"

config() {
	local v

	cp "$DATA_DIR/_hgrc" "$o_homedir/.hgrc"
}

collect() {
	if [ -f "$o_homedir/.hgrc" ]; then
		cp "$o_homedir/.hgrc" "$DATA_DIR/_hgrc"
	fi
}
