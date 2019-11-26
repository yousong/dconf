#!/bin/sh -e

. "$TOPDIR/env.sh"

bundle_dir="$o_homedir/.vim/bundle"

__vim_coc_nvim_bundle="$bundle_dir/coc.nvim"

__vimrc_files="
	$o_homedir/.vimrc
	$o_homedir/.vimrc.plugins
	$o_homedir/.vimrc.basic
"

__vim_foreach_patchdir() {
	find "$PATCH_DIR/_vim" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
}

__vim_has_node() {
	which node &>/dev/null
}

__vim_handle_coc() {
	if [ ! -d "$bundle_dir/coc.nvim" ]; then
		return
	fi

	# It's written in typescript, javascript code available in
	# "release" branch
	git \
		--git-dir "$bundle_dir/coc.nvim/.git" \
		--work-tree "$bundle_dir/coc.nvim" \
		checkout refs/remotes/origin/release
	# Extensions are placed under $o_homedir/.config/coc/
	#
	# "-sync" means waiting for the command finish
	vim -c 'CocInstall -sync coc-tsserver coc-json | q'

	# Update & uninstall extensions
	#CocUpdateSync
	#CocUninstall coc-tsserver
	# Edit config ~/.vim/coc-settings.json
	#CocConfig

	# TODO
	#
	#  - How it works?
	#  - luci.js and friends
	#  - golang packages
	#
	# Languages, https://github.com/neoclide/coc.nvim/wiki/Language-servers
	#
	#  - c/c++/objective-c: ccls
	#    - build big c++ project
	#    - per-project ccls settings
	#  - js/ts: coc-tsserver extension
	#    - how to use it?
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
	if !__vim_has_node; then
		# It requires nodejs (>= 8.10.0)
		__notice "disable coc.nvim because nodejs is not found"
		sed -i -e '/neoclide\/coc.nvim/d' "$o_homedir/.vimrc.plugins"
	fi

	__notice "vim: Installing Vundle packages, this may take a while."
	vim +BundleInstall +qa

	for patchdir in `__vim_foreach_patchdir`; do
		d="$bundle_dir/${patchdir##*/}"
		if [ -d "$d" ]; then
			__info "vim: Patching $d"
			cd "$d"
			git checkout -B dconf refs/remotes/origin/HEAD
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
			git format-patch --output-directory "$patchdir" refs/remotes/origin/HEAD..dconf
		fi
	done
}
