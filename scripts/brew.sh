#!/bin/bash -e

. "$TOPDIR/env.sh"

__brew_ok() {
	[ "$o_os" = "Darwin" ] || return 1
	[ -x "/opt/homebrew/bin/brew" -o -x "/usr/local/bin/brew" ] || return 1
}

config() {
	local d dcore dcask

	__brew_ok || return 0

	# Install homebrew
	#/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"

	d="$(brew --repo)"
	dcore="$d/Library/Taps/homebrew/homebrew-core"
	dcask="$d/Library/Taps/homebrew/homebrew-cask"

	git -C "$d" remote set-url origin https://mirrors.aliyun.com/homebrew/brew.git
	git -C "$dcore" remote set-url origin https://mirrors.aliyun.com/homebrew/homebrew-core.git
	git -C "$dcask" remote set-url origin https://mirrors.aliyun.com/homebrew/homebrew-cask.git

	: git -C "$d" remote set-url origin https://mirrors.ustc.edu.cn/brew.git
	: git -C "$dcore" remote set-url origin https://mirrors.ustc.edu.cn/homebrew-core.git
	: git -C "$dcask" remote set-url origin https://mirrors.ustc.edu.cn/homebrew-cask.git

	# https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/
	: git -C "$d" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
	: git -C "$dcore" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/homebrew-core.git

	: git -C "$d" remote set-url origin https://github.com/Homebrew/brew.git
	: git -C "$dcore" remote set-url origin https://github.com/Homebrew/homebrew-core
	: git -C "$dcask" remote set-url origin https://github.com/caskroom/homebrew-cask

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
	__brew_ok || return 0

	if [ -f "$o_homedir/.Brewfile" ]; then
		cp "$o_homedir/.Brewfile" "$DATA_DIR/_Brewfile"
	fi
}
