#!/bin/bash -e

config() {
	cp "$DATA_DIR/_screenrc" "$o_homedir/.screenrc"
}

collect() {
	if [ -f "$o_homedir/.screenrc" ]; then
		cp "$o_homedir/.screenrc" "$DATA_DIR/_screenrc"
	fi
}
