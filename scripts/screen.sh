#!/bin/sh -e

config() {
	cp "$DATA_DIR/_screenrc" "$HOME/.screenrc"
}

collect() {
	if [ -f "$HOME/.screenrc" ]; then
		cp "$HOME/.screenrc" "$DATA_DIR/_screenrc"
	fi
}
