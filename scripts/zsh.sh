#!/bin/sh -e

. "$TOPDIR/env.sh"

ohmyzsh_dir="$HOME/.oh-my-zsh"

config() {
	[ -d "$ohmyzsh_dir" ] || {
		git clone https://github.com/robbyrussell/oh-my-zsh.git "$ohmyzsh_dir"
		for f in "$PATCH_DIR/_oh-my-zsh"/*; do
			patch -i "$f" -p1
		done
	}

	cp "$DATA_DIR/_zshrc" "$HOME/.zshrc"
	__errmsg "zsh: use 'chsh -s /bin/zsh' to change shell."
}

collect() {
	cp "$HOME/.zshrc" "$DATA_DIR/_zshrc"
}
