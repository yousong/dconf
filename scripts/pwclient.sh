#!/bin/sh -e

. "$TOPDIR/env.sh"

config() {
	cp "$DATA_DIR/_pwclientrc" "$o_homedir/.pwclientrc"
	chmod 600 "$o_homedir/.pwclientrc"
}

collect() {
	if [ -f "$o_homedir/.pwclientrc" ]; then
		cp "$o_homedir/.pwclientrc" "$DATA_DIR/_pwclientrc"
	fi
}
