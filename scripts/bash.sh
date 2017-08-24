#!/bin/sh -e

. "$TOPDIR/env.sh"

config() {
	cp "$DATA_DIR/_bashrc" "$o_homedir/.bashrc"
}

collect() {
	if [ -f "$o_homedir/.bashrc" ]; then
		cp "$o_homedir/.bashrc" "$DATA_DIR/_bashrc"
	fi
}
