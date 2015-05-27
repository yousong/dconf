#!/bin/sh -e

. "$TOPDIR/env.sh"

bundle_dir="$HOME/.vim/bundle"

config() {
	local vundle_repo="$bundle_dir/Vundle.vim"
	local plugin d

	if [ ! -d "$vundle_repo/.git" ]; then
		git clone https://github.com/gmarik/Vundle.vim.git "$vundle_repo"
	fi

	cp "$DATA_DIR/_vimrc" "$HOME/.vimrc"

	__errmsg "vim: Installing Vundle packages, this may take quite a while."
	vim +BundleInstall +qa

	for plugin in $(find "$PATCH_DIR/_vim" -depth 2 -type d); do
		d="$bundle_dir/$(basename "$plugin")"
		if [ -d "$d" ]; then
			cd "$d"
			git checkout -b dconf >/dev/null 2>&1 || true
			git reset --hard master
			git am "$plugin"/*
		fi
	done
}

collect() {
	if [ -f "$HOME/.vimrc" ]; then
		cp "$HOME/.vimrc" "$DATA_DIR/_vimrc"
	fi
}
