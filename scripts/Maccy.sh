#!/bin/bash -e

. "$TOPDIR/env.sh"

Maccy_dir="$o_homedir/Library/Containers/org.p0deje.Maccy/Data/Library/Application Support/Maccy"
Maccy_db="$Maccy_dir/Storage.sqlite"

config_private_data() {
	local backup_db="$DATA_PRIVATE_DIR/Maccy/${Maccy_db##*/}"
	if ! test -s "$backup_db"; then
		return
	fi
	if ! test -s "$Maccy_db"; then
		return
	fi
	if ! test "$backup_db" -nt "$Maccy_db"; then
		__notice_private "Maccy: skip as the backup db is NOT newer than $Maccy_db"
		return
	fi

	cp "$backup_db" "$Maccy_db"
}

collect_private_data() {
	if ! test -d "$Maccy_dir"; then
		return
	fi

	mkdir -p "$DATA_PRIVATE_DIR/Maccy"
	cp "$Maccy_db" "$DATA_PRIVATE_DIR/Maccy/${Maccy_db##*/}"
}
