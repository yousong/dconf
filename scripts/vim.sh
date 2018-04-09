#!/bin/sh -e

. "$TOPDIR/env.sh"

bundle_dir="$o_homedir/.vim/bundle"

__vimrc_files="
	$o_homedir/.vimrc
	$o_homedir/.vimrc.plugins
	$o_homedir/.vimrc.basic
"

__vim_foreach_patchdir() {
	find "$PATCH_DIR/_vim" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
}

config() {
	local f dataf
	local vundle_repo="$bundle_dir/Vundle.vim"
	local patchdir d

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

	__notice "vim: Installing Vundle packages, this may take a while."
	vim +BundleInstall +qa

	for patchdir in `__vim_foreach_patchdir`; do
		d="$bundle_dir/${patchdir##*/}"
		if [ -d "$d" ]; then
			cd "$d"
			git checkout -b dconf >/dev/null 2>&1 || true
			git reset --hard master
			git am "$patchdir"/*
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

refresh_patches() {
	local d

	for patchdir in `__vim_foreach_patchdir`; do
		d="$bundle_dir/${patchdir##*/}"
		if [ -d "$d" ]; then
			cd "$d"
			rm -vf "$patchdir"/*
			git format-patch --output-directory "$patchdir" master..dconf
		fi
	done
}
