#!/usr/bin/env bash

email="zhouyousong AT yunionyun.com"
email="${email/ AT /@}"

set_user() {
	local gitdir="$1"

	echo "working on $gitdir" >&2
	git --git-dir="$gitdir" config user.name "Yousong Zhou"
	git --git-dir="$gitdir" config user.email "$email"
}

all() {
	find $GOPATH/src/yunion.io/x -maxdepth 2 -name .git -type d \
		| while read d; do \
			set_user "$d"; \
		done

	find $HOME/yun -maxdepth 2 -name .git -type d \
		| while read d; do \
			set_user "$d"; \
		done

	return 0
}

this() {
	local d="$(pwd)"
	local gitdir

	while [ "$d" != "/" ]; do
		if [ -d "$d/.git" ]; then
			gitdir="$d/.git"
			break
		fi
		d="$(readlink -f "$d/..")"
	done
	if [ -n "$gitdir" ]; then
		set_user "$gitdir"
	else
		echo "cannot find .git dir up to the root" >&2
		return 1
	fi
}

case "$1" in
	all|this)
		"$1"
		;;
	*)
		echo "usage: $0 all" >&2
		echo "usage: $0 this" >&2
		;;
esac
