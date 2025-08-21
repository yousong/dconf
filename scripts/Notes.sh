#!/bin/bash -e

. "$TOPDIR/env.sh"

Notes_dir="$o_homedir/Library/Group Containers/group.com.apple.notes"
Notes_db="$Notes_dir/NoteStore.sqlite"

config_private_data() {
	__config_private_data \
		Notes \
		"$Notes_db" \
		"$DATA_PRIVATE_DIR/Notes/${Notes_db##*/}"

	__config_private_data \
		Notes \
		"$Notes_dir/Accounts/LocalAccount" \
		"$DATA_PRIVATE_DIR/Notes/LocalAccount"
}

collect_private_data() {
	__collect_private_data \
		Notes \
		"$Notes_db" \
		"$DATA_PRIVATE_DIR/Notes/${Notes_db##*/}"

	__collect_private_data \
		Notes \
		"$Notes_dir/Accounts/LocalAccount" \
		"$DATA_PRIVATE_DIR/Notes/LocalAccount"
}
