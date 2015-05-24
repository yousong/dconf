#!/bin/sh -e

. "$TOPDIR/env.sh"

usrenv_dir="$HOME/.usr.env"
dircolors_repo="$usrenv_dir/dircolors-solarized"

config() {
	if [ ! -d "$dircolors_repo/.git" ]; then
		git clone https://github.com/seebi/dircolors-solarized.git "$dircolors_repo"
	fi

	cp "$DATA_DIR/_usr.env/" "$usrenv_dir"
}

collect() {
	rm -rf "$DATA_DIR/.usr.env"
	cp "$HOME/.usr.env" "$DATA_DIR/_usr.env"
	rm -rf "$DATA_DIR/_usr.env/dircolors-solarized"
	# .env.sh within _usr.env/ are not copied
	rm -f "$DATA_DIR/_usr.env/.env.sh"
}
