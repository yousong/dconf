#!/bin/sh -e

. "$TOPDIR/env.sh"

config() {
	local v

	cp "$DATA_DIR/_gitconfig" "$HOME/.gitconfig"

	# Debian wheezy may have a 4th digit as patch level.
	v="$(git --version | cut -f 3 -d ' ')"
	v="$(echo "$v" | cut -f 1,2,3 -d . | tr . ' ')"
	v="$(printf "%02d%02d%02d" $v)"

	# push.default=simple is only available since 1.7.11
	#  - https://github.com/git/git/blob/master/Documentation/RelNotes/1.7.11.txt
	if [ "$v" -lt "010711" ]; then
		# unsetting an non-existing option will exit with 5.
		git config --global --unset push.default || true
	fi
}

collect() {
	cp "$HOME/.gitconfig" "$DATA_DIR/_gitconfig"
}
