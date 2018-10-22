#!/bin/sh -e

. "$TOPDIR/env.sh"

ohmyzsh_dir="$o_homedir/.oh-my-zsh"
ohmyzsh_c_dir="$ohmyzsh_dir/custom"
ohmyzsh_cp_dir="$ohmyzsh_c_dir/plugins"

config() {
	local p

	[ -d "$ohmyzsh_dir" ] || {
		git clone https://github.com/robbyrussell/oh-my-zsh.git "$ohmyzsh_dir"
	}

	for p in \
			zsh-autosuggestions \
			zsh-syntax-highlighting \
			; do
		[ -d "$ohmyzsh_cp_dir/$p" ] || {
			git clone "https://github.com/zsh-users/$p" "$ohmyzsh_cp_dir/$p"
		}
	done

	cd "$ohmyzsh_dir"
	git checkout -B dconf origin/master
	git am "$PATCH_DIR/_oh-my-zsh"/*

	cp "$DATA_DIR/_zshrc" "$o_homedir/.zshrc"
	__notice "zsh: use 'chsh -s /bin/zsh' to change shell."
}

collect() {
	if [ -f "$o_homedir/.zshrc" ]; then
		cp "$o_homedir/.zshrc" "$DATA_DIR/_zshrc"
	fi
}
