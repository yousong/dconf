#!/bin/sh -e

. "$TOPDIR/env.sh"

fzf_dir="$o_homedir/.fzf"

config() {
	[ -d "$fzf_dir" ] || {
		go get -u github.com/junegunn/fzf
		git clone https://github.com/junegunn/fzf.git "$fzf_dir"
	}
}
