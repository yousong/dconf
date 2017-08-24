#!/bin/sh -e

. "$TOPDIR/env.sh"

config() {
	cp "$DATA_DIR/_ccache" "$o_homedir/.ccache"
}

collect() {
	if [ -f "$o_homedir/.ccache/ccache.conf" ]; then
		cp "$o_homedir/.ccache/ccache.conf" "$DATA_DIR/_ccache/ccache.conf"
	fi
}
