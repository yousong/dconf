#!/bin/bash -e

. "$TOPDIR/env.sh"

config() {
	cp "$DATA_DIR/_gdbinit" "$o_homedir/.gdbinit"
}

collect() {
	if [ -f "$o_homedir/.gdbinit" ]; then
		cp "$o_homedir/.gdbinit" "$DATA_DIR/_gdbinit"
	fi
}
