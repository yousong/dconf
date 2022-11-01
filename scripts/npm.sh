#!/bin/sh -e

. "$TOPDIR/env.sh"

npm_conf="$o_homedir/.npmrc"

config() {
	cp "$DATA_DIR/_npmrc" "$npm_conf"
}

collect() {
	if [ -f "$npm_conf" ]; then
		cp "$npm_conf" "$DATA_DIR/_npmrc"
	fi
}
