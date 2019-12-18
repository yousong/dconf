#!/bin/sh -e

. "$TOPDIR/env.sh"

ohmyzsh_dir="$o_homedir/.oh-my-zsh"
ohmyzsh_c_dir="$ohmyzsh_dir/custom"
ohmyzsh_cp_dir="$ohmyzsh_c_dir/plugins"

__ohmyzsh_foreach_patchdir() {
	find "$PATCH_DIR/_oh-my-zsh" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
}

config() {
	local p d

	[ -d "$ohmyzsh_dir" ] || {
		git clone https://github.com/robbyrussell/oh-my-zsh.git "$ohmyzsh_dir"
	}

	for p in \
			zsh-autosuggestions \
			zsh-syntax-highlighting \
			; do
		[ -d "$ohmyzsh_cp_dir/$p" ] || {
			git clone "https://github.com/zsh-users/$p" "$ohmyzsh_cp_dir/$p"
		}
	done

	cd "$ohmyzsh_dir"
	git checkout -B dconf origin/master
	git am "$PATCH_DIR/_oh-my-zsh"/*

	for patchdir in `__ohmyzsh_foreach_patchdir`; do
		d="$ohmyzsh_cp_dir/${patchdir##*/}"
		if [ -d "$d" ]; then
			__info "zsh: Patching $d"
			cd "$d"
			git checkout -B dconf refs/remotes/origin/HEAD
			git am "$patchdir"/*
		fi
	done

	cp "$DATA_DIR/_zshrc" "$o_homedir/.zshrc"
	if ! grep -q "^$USER\>.*/zsh" /etc/passwd &>/dev/null; then
		__notice "zsh: use 'chsh -s /bin/zsh' to change shell."
	fi
	if ls "$o_homedir/".zcompdump* &>/dev/null; then
		__notice "zsh: rm $o_homedir/.zcompdump* if completion does not work"
	fi
}

collect() {
	if [ -f "$o_homedir/.zshrc" ]; then
		cp "$o_homedir/.zshrc" "$DATA_DIR/_zshrc"
	fi
}

refresh_patches() {
	local d

	cd "$ohmyzsh_dir"
	git format-patch --output-directory "$PATCH_DIR/_oh-my-zsh" refs/remotes/origin/HEAD..dconf

	for patchdir in `__ohmyzsh_foreach_patchdir`; do
		d="$ohmyzsh_cp_dir/${patchdir##*/}"
		if [ -d "$d" ]; then
			cd "$d"
			rm -vf "$patchdir"/*
			git format-patch --output-directory "$patchdir" refs/remotes/origin/HEAD..dconf
		fi
	done
}
