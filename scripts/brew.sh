#!/bin/sh -e

. "$TOPDIR/env.sh"

ohmyzsh_dir="$o_homedir/.oh-my-zsh"
ohmyzsh_c_dir="$ohmyzsh_dir/custom"
ohmyzsh_cp_dir="$ohmyzsh_c_dir/plugins"

__brew_ok() {
	[ "$o_os" = "Darwin" ] || return 1
	[ -x "/usr/local/bin/brew" ] || return 1
}

config() {
	local d

	__brew_ok || return

	# Install homebrew
	#/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

	d="$(brew --repo)"
	cd "$d";					 git remote set-url origin https://mirrors.ustc.edu.cn/brew.git
	cd "$d/Library/Taps/homebrew/homebrew-core";	 git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git
	cd "$d/Library/Taps/homebrew/homebrew-cask";	 git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git

	: cd "$d";					 git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
	: cd "$d/Library/Taps/homebrew/homebrew-core";	 git remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git
	: cd "$d/Library/Taps/homebrew/homebrew-cask";	 git remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git

	: cd "$d";					 git remote set-url origin https://github.com/Homebrew/brew.git
	: cd "$d/Library/Taps/homebrew/homebrew-core";	 git remote set-url origin https://github.com/Homebrew/homebrew-core
	: cd "$d/Library/Taps/homebrew/homebrew-cask";	 git remote set-url origin https://github.com/caskroom/homebrew-cask

	if [ -f "$o_homedir/.Brewfile" ]; then
		cp "$DATA_DIR/_Brewfile" "$o_homedir/.Brewfile"
		__notice "brew: run the following to sync with $o_homedir/.Brewfile"
		__notice ""
		__notice "	brew bundle --global install"
		__notice "	brew bundle --global cleanup"
		__notice "	#brew bundle --global --force cleanup"
		__notice ""
	else
		__notice "brew: $o_homedir/.Brewfile is not available yet, dump it"
		__notice ""
		__notice "	brew bundle --global dump"
		__notice ""
	fi
}

collect() {
	__brew_ok || return

	if [ -f "$o_homedir/.Brewfile" ]; then
		cp "$o_homedir/.Brewfile" "$DATA_DIR/_Brewfile"
	fi
}
