#!/bin/sh -e

tmux_plugins_dir="$HOME/.tmux/plugins"
tpm_dir="$tmux_plugins_dir/tpm"

config() {
	mkdir -p "$tmux_plugins_dir"
	[ -x "$tmux_plugins_dir/tpm/tpm" ] || {
		git clone https://github.com/tmux-plugins/tpm "$tpm_dir"
	}

	cp "$DATA_DIR/_tmux.conf" "$HOME/.tmux.conf"
	__errmsg "tmux: install plugins with <PREFIX+I>."
}

collect() {
	if [ -f "$HOME/.tmux.conf" ]; then
		cp "$HOME/.tmux.conf" "$DATA_DIR/_tmux.conf"
	fi
}
