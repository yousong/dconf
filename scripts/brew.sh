#!/bin/bash -e

. "$TOPDIR/env.sh"

__brew_ok() {
	[ "$o_os" = "Darwin" ] || return 1
	[ -x "/opt/homebrew/bin/brew" -o -x "/usr/local/bin/brew" ] || return 1
}

config() {
	__brew_ok || return 0

	# Install homebrew
	#/usr/bin/ruby -e "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/master/install)"
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
