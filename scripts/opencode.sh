#!/bin/bash -e

. "$TOPDIR/env.sh"

config() {
	if [ -f "$DATA_DIR/_opencode.jsonc" ]; then
		mkdir -p "$o_homedir/.config/opencode"
		cp "$DATA_DIR/_opencode.jsonc" "$o_homedir/.config/opencode/opencode.jsonc"
	fi
}

collect() {
	if [ -f "$o_homedir/.config/opencode/opencode.jsonc" ]; then
		cp "$o_homedir/.config/opencode/opencode.jsonc" "$DATA_DIR/_opencode.jsonc"
	fi
}
