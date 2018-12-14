#!/bin/sh -e

. "$TOPDIR/env.sh"

usrenv_dir="$o_homedir/.usr.env"
dircolors_repo="$usrenv_dir/dircolors-solarized"

config() {
	if [ ! -d "$dircolors_repo/.git" ]; then
		git clone https://github.com/seebi/dircolors-solarized.git "$dircolors_repo"
	fi

	find "$usrenv_dir" -maxdepth 1 -type f -name '*.plugin.sh' \
		| xargs rm -f
	cp -a "$DATA_DIR/_usr.env/" "$usrenv_dir"
}

collect() {
	rm -rf "$DATA_DIR/_usr.env"
	if [ -d "$o_homedir/.usr.env" ]; then
		cp -a "$o_homedir/.usr.env" "$DATA_DIR/_usr.env"
	fi
	rm -rf "$DATA_DIR/_usr.env/dircolors-solarized"
	# .env.sh within _usr.env/ are not copied
	rm -f "$DATA_DIR/_usr.env/.env.sh"
}
