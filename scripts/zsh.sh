#!/bin/sh -e

. "$TOPDIR/env.sh"

ohmyzsh_dir="$o_homedir/.oh-my-zsh"

config() {
	[ -d "$ohmyzsh_dir" ] || {
		git clone https://github.com/robbyrussell/oh-my-zsh.git "$ohmyzsh_dir"
	}

	cd "$ohmyzsh_dir"
	git checkout -b dconf >/dev/null 2>&1 || true
	git reset --hard master
	git am "$PATCH_DIR/_oh-my-zsh"/*

	cp "$DATA_DIR/_zshrc" "$o_homedir/.zshrc"
	__errmsg "zsh: use 'chsh -s /bin/zsh' to change shell."
}

collect() {
	if [ -f "$o_homedir/.zshrc" ]; then
		cp "$o_homedir/.zshrc" "$DATA_DIR/_zshrc"
	fi
}
