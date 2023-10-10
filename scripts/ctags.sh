#!/bin/bash -e

. "$TOPDIR/env.sh"

config() {
	cp "$DATA_DIR/_ctags" "$o_homedir/.ctags"
}

collect() {
	if [ -f "$o_homedir/.ctags" ]; then
		cp "$o_homedir/.ctags" "$DATA_DIR/_ctags"
	fi
}
