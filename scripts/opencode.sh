#!/bin/bash -e

. "$TOPDIR/env.sh"

config() {
	if [ -f "$DATA_DIR/opencode.jsonc" ]; then
		mkdir -p "$o_homedir/.config/opencode"
		cp "$DATA_DIR/opencode.jsonc" "$o_homedir/.config/opencode/opencode.jsonc"
	fi
	if [ -d "$DATA_DIR/opencode/_instructions" ]; then
		mkdir -p "$o_homedir/.config/opencode/_instructions"
		cp -a "$DATA_DIR/opencode/_instructions/." "$o_homedir/.config/opencode/_instructions/"
	fi
}

collect() {
	if [ -f "$o_homedir/.config/opencode/opencode.jsonc" ]; then
		cp "$o_homedir/.config/opencode/opencode.jsonc" "$DATA_DIR/opencode.jsonc"
	fi
	if [ -d "$o_homedir/.config/opencode/_instructions" ]; then
		mkdir -p "$DATA_DIR/opencode/_instructions"
		cp -a "$o_homedir/.config/opencode/_instructions/." "$DATA_DIR/opencode/_instructions/"
	fi
}
