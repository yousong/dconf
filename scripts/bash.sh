#!/bin/sh -e

. "$TOPDIR/env.sh"

config() {
	cp "$DATA_DIR/_bashrc" "$HOME/.bashrc"
}

collect() {
	if [ -f "$HOME/.bashrc" ]; then
		cp "$HOME/.bashrc" "$DATA_DIR/_bashrc"
	fi
}
