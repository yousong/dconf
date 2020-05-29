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

__vim_handle_ycm() {
	local wd="$bundle_dir/YouCompleteMe"
	[ -d "$wd" ] || return 0
	[ ! -f "$wd/.dconf_done" ] || return 0

	# Installation is done mainly by third_party/ycmd/build.py
	#
	# Binaries were downloaded from https://dl.bintray.com/ycm-core .
	# Version numbers are hardcoded in the build.py script.  Note that the
	# downloaded version may require newer versions of libc and cannot be
	# run on systems like CentOS 7
	#
	# Dependencies are put in its own subdirectory in
	# third_party/ycmd/third_party
	#
	# Arguments
	#
	#   --all			enable all completer
	#   --clangd-completer		clangd
	#   --go-completer		"go build" local gopls copy
	#
	"$wd/install.py" \
		--clangd-completer \

	local ycm_clangd="$wd/third_party/ycmd/third_party/clangd/output/bin/clangd"
	if ! "$ycm_clangd" --version >/dev/null; then
		local clangd="$(echo $o_homedir/.usr/toolchain/llvm-*/bin/clangd \
					| sort --version-sort --reverse \
					| head -n 1)"
		if "$clangd" --version >/dev/null; then
			if [ ! -e "$ycm_clangd.ycm" ]; then
				mv "$ycm_clangd" "$ycm_clangd.ycm"
			fi
			ln -sf "$clangd" "$ycm_clangd"
		fi
	fi
	touch "$wd/.dconf_done"
}

__vim_bundle_ref() {
	local name="$1"

	case "$name" in
		vim-go) echo "v1.23" ;;
		*) echo "refs/remotes/origin/HEAD" ;;
	esac
}

config() {
	local f dataf
	local vundle_repo="$bundle_dir/Vundle.vim"
	local patchdir d name

	if ! vim --version &>/dev/null; then
		__notice "vim: skipped because vim was not found"
		return
	fi

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
		name="${patchdir##*/}"
		d="$bundle_dir/$name"
		if [ -d "$d" ]; then
			__info "vim: Patching $d"
			cd "$d"
			git checkout -B dconf "$(__vim_bundle_ref "$name")"
			git am "$patchdir"/*
		fi
	done

	__vim_handle_ycm
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
	local patchdir d name

	for patchdir in `__vim_foreach_patchdir`; do
		name="${patchdir##*/}"
		d="$bundle_dir/$name"
		if [ -d "$d" ]; then
			rm -vf "$patchdir"/*
			format_patch "$d" "$patchdir" "$(__vim_bundle_ref "$name")"..dconf
		fi
	done
}
