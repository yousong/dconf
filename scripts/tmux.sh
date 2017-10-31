#!/bin/sh -e

tmux_plugins_dir="$o_homedir/.tmux/plugins"
tpm_dir="$tmux_plugins_dir/tpm"

config() {
	local ver

	mkdir -p "$tmux_plugins_dir"
	[ -x "$tmux_plugins_dir/tpm/tpm" ] || {
		git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
	}

	cp "$DATA_DIR/_tmux.conf" "$o_homedir/.tmux.conf"

	# from "tmux 2.1" to "21"
	ver="$(tmux -V | tr -cd '0-9')"
	if [ "$ver" -lt 21 ]; then
		# these are only supported since tmux 2.1
		sed -i''	\
			-e '/set-option .* mouse /d' \
			-e '/bind-key .* WheelUpPane /d' \
			-e '/bind-key .* WheelDownPane /d' \
			"$o_homedir/.tmux.conf"
	fi
	__notice "tmux: install plugins with <PREFIX+I>."
}

collect() {
	if [ -f "$o_homedir/.tmux.conf" ]; then
		cp "$o_homedir/.tmux.conf" "$DATA_DIR/_tmux.conf"
	fi
}
