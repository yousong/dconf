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

	# https://mirrors.tuna.tsinghua.edu.cn/help/homebrew/
	#
	# 注：自 brew 4.0.0 (2023 年 2 月 16 日) 起，HOMEBREW_INSTALL_FROM_API 会成为默认行为，无需设置。大部分用户无需再克隆 homebrew-core 仓库，故无需设置 HOMEBREW_CORE_GIT_REMOTE 环境变量；但若需要运行 brew 的开发命令或者 brew 安装在非官方支持的默认 prefix 位置，则仍需设置 HOMEBREW_CORE_GIT_REMOTE 环境变量。如果不想通过 API 安装，可以设置 HOMEBREW_NO_INSTALL_FROM_API=1。
	#
	git -C "$d" remote set-url origin https://mirrors.aliyun.com/homebrew/brew.git
	: git -C "$d" remote set-url origin https://mirrors.tuna.tsinghua.edu.cn/git/homebrew/brew.git
	: git -C "$d" remote set-url origin https://mirrors.ustc.edu.cn/brew.git
	: git -C "$d" remote set-url origin https://github.com/Homebrew/brew.git

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
