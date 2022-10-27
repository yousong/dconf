#!/bin/sh -e

. "$TOPDIR/env.sh"

fzf_ver=0.34.0

fzf_dir="$o_homedir/.fzf"
fzf_bindir="$o_homedir/.usr/bin"
fzf_bin="$fzf_bindir/fzf"

config() {
	local v

	if [ -x "$fzf_bin" ]; then
		v="$("$fzf_bin" --version)"
		v="${v% *}"
	fi

	[ "$v" = "$fzf_ver" ] || {
		local f url
		case "$o_os" in
			Darwin) f="fzf-$fzf_ver-darwin_amd64.tar.gz" ;;
			Linux) f="fzf-$fzf_ver-linux_amd64.tar.gz" ;;
			*) __error "unknown os $o_os"; false; ;;
		esac
		url="https://github.com/junegunn/fzf/releases/download/$fzf_ver/$f"

		__info "downloading $f"
		wget -c -O /tmp/fzf.tgz "$url"
		mkdir -p "$fzf_bindir"
		tar -xzf /tmp/fzf.tgz -C "$fzf_bindir"
		rm -f /tmp/fzf.tgz
	}

	[ -d "$fzf_dir" ] || {
		git clone https://github.com/junegunn/fzf.git "$fzf_dir"
	}
	git \
		--work-tree "$fzf_dir" \
		--git-dir "$fzf_dir/.git" \
		checkout -B "$fzf_ver" "$fzf_ver"
}
