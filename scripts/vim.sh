#!/bin/sh -e

. "$TOPDIR/env.sh"

vundle_repo="$HOME/.vim/bundle/Vundle.vim"

config() {
	if [ ! -d "$vundle_repo/.git" ]; then
		git clone https://github.com/gmarik/Vundle.vim.git "$vundle_repo"
	fi

	cp "$DATA_DIR/_vimrc" "$HOME/.vimrc"

	__errmsg "vim: Installing Vundle packages, this may take quite a while."
	vim +BundleInstall +qa
}

collect() {
	if [ -f "$HOME/.vimrc" ]; then
		cp "$HOME/.vimrc" "$DATA_DIR/_vimrc"
	fi
}
