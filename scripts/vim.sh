#!/bin/sh -e

. "$TOPDIR/env.sh"

bundle_dir="$HOME/.vim/bundle"

__vimrc_files="
	$HOME/.vimrc
	$HOME/.vimrc.plugins
	$HOME/.vimrc.basic
"

config() {
	local f dataf
	local vundle_repo="$bundle_dir/Vundle.vim"
	local plugin d

	if [ ! -d "$vundle_repo/.git" ]; then
		git clone https://github.com/gmarik/Vundle.vim.git "$vundle_repo"
	fi

	for f in $__vimrc_files; do
		dataf="${f##*/.}"
		dataf="$DATA_DIR/_$dataf"
		if [ -f "$dataf" ]; then
			cp "$dataf" "$f"
		fi
	done

	__errmsg "vim: Installing Vundle packages, this may take quite a while."
	vim +BundleInstall +qa

	for plugin in $(find "$PATCH_DIR/_vim" -mindepth 1 -maxdepth 1 -type d 2>/dev/null); do
		d="$bundle_dir/${plugin##*/}"
		if [ -d "$d" ]; then
			cd "$d"
			git checkout -b dconf >/dev/null 2>&1 || true
			git reset --hard master
			git am "$plugin"/*
		fi
	done
}

collect() {
	local f dataf

	for f in $__vimrc_files; do
		if [ -f "$f" ]; then
			dataf="${f##*/.}"
			dataf="$DATA_DIR/_$dataf"
			cp "$f" "$dataf"
		fi
	done
}
