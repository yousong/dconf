#!/bin/sh -e

. "$TOPDIR/env.sh"

config() {
	local v

	cp "$DATA_DIR/_gitconfig" "$HOME/.gitconfig"
}

collect() {
	if [ -f "$HOME/.gitconfig" ]; then
		cp "$HOME/.gitconfig" "$DATA_DIR/_gitconfig"
	fi
}
