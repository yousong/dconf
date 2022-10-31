#!/bin/sh -e

. "$TOPDIR/env.sh"

npm_conf="$o_homedir/.npmrc"

config() {
	cp "$DATA_DIR/_m2/settings.xml" "$npm_conf"
}

collect() {
	if [ -f "$npm_conf" ]; then
		cp "$npm_conf" "$DATA_DIR/_npmrc"
	fi
}
