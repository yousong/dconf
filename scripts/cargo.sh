#!/bin/bash -e

. "$TOPDIR/env.sh"

cargo_conf_dir="$o_homedir/.cargo"
cargo_conf="$o_homedir/.cargo/config"

config() {
	mkdir -p "$cargo_conf_dir"
	chmod 700 "$cargo_conf_dir"
	cp "$DATA_DIR/_cargo/config" "$cargo_conf"
	chmod 600 "$cargo_conf"
}

collect() {
	if [ -f "$cargo_conf" ]; then
		mkdir -p "$DATA_DIR/_cargo"
		cp "$cargo_conf" "$DATA_DIR/_cargo/config"
	fi
}
