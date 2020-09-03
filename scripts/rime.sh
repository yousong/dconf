#!/bin/sh -e

. "$TOPDIR/env.sh"

fzf_ver=0.21.1

rime_dir() {
	case "$o_os" in
		Darwin) echo "$HOME/Library/Rime" ;;
		Linux) echo "$HOME/.config/ibus/rime" ;;
	esac
}

rime_rm_symlinks() {
	local rd="$(rime_dir)"

	if [ -d "$rd" ]; then
		find "$rd" -maxdepth 1 -type l | xargs rm -vf
	fi
}

config() {
	local rd="$(rime_dir)"

	if [ -d "$rd" ]; then
		if [ ! -d "$rd/rime-wubi" ]; then
			git clone https://github.com/rime/rime-wubi.git "$rd/rime-wubi"
		fi
		rime_rm_symlinks
		ln -sf rime-wubi/wubi86.dict.yaml "$rd/wubi86.dict.yaml"
		ln -sf rime-wubi/wubi86.schema.yaml "$rd/wubi86.schema.yaml"
		cp "$DATA_DIR/_rime.default.custom.yaml" "$rd/default.custom.yaml"
	fi
}

collect() {
	local rd="$(rime_dir)"

	if [ -s "$rd/default.custom.yaml" ]; then
		cp "$rd/default.custom.yaml" "$DATA_DIR/_rime.default.custom.yaml"
	fi
}
