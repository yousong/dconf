#!/bin/sh -e

. "$TOPDIR/env.sh"

config() {
	cp "$DATA_DIR/_pwclientrc" "$o_homedir/.pwclientrc"
	chmod 600 "$o_homedir/.pwclientrc"
	__notice "$o_homedir/.pwclientrc: password is not set yet"
}

collect() {
	if [ -f "$o_homedir/.pwclientrc" ]; then
		cp "$o_homedir/.pwclientrc" "$DATA_DIR/_pwclientrc"
		__notice "$o_homedir/.pwclientrc: plaintext password within"
	fi
}
