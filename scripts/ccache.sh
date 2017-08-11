#!/bin/sh -e

. "$TOPDIR/env.sh"

config() {
	cp "$DATA_DIR/_ccache" "$HOME/.ccache"
}

collect() {
	if [ -f "$HOME/.ccache/ccache.conf" ]; then
		cp "$HOME/.ccache/ccache.conf" "$DATA_DIR/_ccache/ccache.conf"
	fi
}
