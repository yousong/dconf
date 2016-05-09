#!/bin/sh -e

. "$TOPDIR/env.sh"

config() {
	cp "$DATA_DIR/_ctags" "$HOME/.ctags"
}

collect() {
	if [ -f "$HOME/.ctags" ]; then
		cp "$HOME/.ctags" "$DATA_DIR/_ctags"
	fi
}
