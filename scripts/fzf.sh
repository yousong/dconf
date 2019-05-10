#!/bin/sh -e

. "$TOPDIR/env.sh"

fzf_ver=0.18.0
fzf_dir="$o_homedir/.fzf"

config() {
	[ -d "$fzf_dir" ] || {
		go get -u github.com/junegunn/fzf || {
			local f url
			case "$o_os" in
				Darwin) f="fzf-$fzf_ver-darwin_amd64.tgz" ;;
				Linux) f="fzf-$fzf_ver-linux_amd64.tgz" ;;
				*) __error "unknown os $o_os"; false; ;;
			esac
			url="https://github.com/junegunn/fzf-bin/releases/download/$fzf_ver/$f"

			__warning "downloading $f"
			wget -O /tmp/fzf.tgz "$url"
			mkdir -p "$HOME/.usr/bin"
			tar -xzf /tmp/fzf.tgz -C "$HOME/.usr/bin/"
			rm -f /tmp/fzf/tgz
		}
		git clone https://github.com/junegunn/fzf.git "$fzf_dir"
	}
}
