#!/bin/bash -e

. "$TOPDIR/env.sh"

config() {
	local v

	cp "$DATA_DIR/_gitconfig" "$o_homedir/.gitconfig"
}

collect() {
	if [ -f "$o_homedir/.gitconfig" ]; then
		cp "$o_homedir/.gitconfig" "$DATA_DIR/_gitconfig"
	fi
}
