#!/bin/bash -e

. "$TOPDIR/env.sh"

Maccy_dir="$o_homedir/Library/Containers/org.p0deje.Maccy/Data/Library/Application Support/Maccy"
Maccy_db="$Maccy_dir/Storage.sqlite"

config_private_data() {
	__config_private_data \
		Maccy \
		"$Maccy_db" \
		"$DATA_PRIVATE_DIR/Maccy/${Maccy_db##*/}"
}

collect_private_data() {
	__collect_private_data \
		Maccy \
		"$Maccy_db" \
		"$DATA_PRIVATE_DIR/Maccy/${Notes_db##*/}"
}
