#!/bin/sh -e

. "$TOPDIR/env.sh"

config() {
	local v

	cp "$DATA_DIR/_hgrc" "$HOME/.hgrc"
}

collect() {
	if [ -f "$HOME/.hgrc" ]; then
		cp "$HOME/.hgrc" "$DATA_DIR/_hgrc"
	fi
}
