#!/bin/bash -e

. "$TOPDIR/env.sh"

config() {
	local v

	if [ -f "$DATA_DIR/_claude_settings.json" ]; then
		mkdir -p "$o_homedir/.claude"
		cp "$DATA_DIR/_claude_settings.json" "$o_homedir/.claude/settings.json"
	fi
}

collect() {
	if [ -f "$o_homedir/.claude/settings.json" ]; then
		cp "$o_homedir/.claude/settings.json" "$DATA_DIR/_claude_settings.json"
	fi
}
