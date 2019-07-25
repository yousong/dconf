#!/bin/sh -e

. "$TOPDIR/env.sh"

maven_conf_dir="$o_homedir/.m2"
maven_conf="$o_homedir/.m2/settings.xml"

config() {
	mkdir -p "$maven_conf_dir"
	cp "$DATA_DIR/_m2/settings.xml" "$maven_conf"
}

collect() {
	if [ -f "$maven_conf" ]; then
		mkdir -p "$DATA_DIR/_m2"
		cp "$maven_conf" "$DATA_DIR/_m2/settings.xml"
	fi
}
