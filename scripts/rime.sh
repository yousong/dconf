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

rime_cp_custom_yaml() {
	local src="$1"; shift
	local dst="$1"; shift

	if [ "$src" = "$DATA_DIR" ]; then
		find "$src" -maxdepth 1 -name "_rime.*.custom.yaml" -type f \
			| while read srcf; do
				dstf="$(basename "$srcf")"
				dstf="${dstf#_rime.}"
				cp "$srcf" "$dst/$dstf"
			done
	else
		find "$src" -maxdepth 1 -name "*.custom.yaml" -type f \
			| while read srcf; do
				dstf="$(basename "$srcf")"
				dstf="_rime.$dstf"
				cp "$srcf" "$dst/$dstf"
			done
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

		rime_cp_custom_yaml "$DATA_DIR" "$rd"
	fi
}

collect() {
	local rd="$(rime_dir)"

	if [ -s "$rd/default.custom.yaml" ]; then
		cp "$rd/default.custom.yaml" "$DATA_DIR/_rime.default.custom.yaml"
		cp "$rd/wubi86.custom.yaml" "$DATA_DIR/_rime.wubi86.custom.yaml"

		rime_cp_custom_yaml "$rd" "$DATA_DIR"
	fi
}
