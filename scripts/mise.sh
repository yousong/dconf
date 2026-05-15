#!/bin/bash -e

. "$TOPDIR/env.sh"

mise_conf="$o_homedir/.config/mise/config.toml"

config() {
	mkdir -p "${mise_conf%/*}"
	cp "$DATA_DIR/_mise_config.toml" "$mise_conf"
}

collect() {
	if [ -f "$mise_conf" ]; then
		mkdir -p "${DATA_DIR%/*}"
		cp "$mise_conf" "$DATA_DIR/_mise_config.toml"
	fi
}
