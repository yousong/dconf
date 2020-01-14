#!/usr/bin/env bash

arg0="$(basename "$0")"
s="./_output/bin"
t="/opt/yunion/bin"

quo=

if test -L "$s"; then
	quo=link
elif test -d "$s"; then
	quo=dir
else
	echo "$arg0: unknown filetype of $s" >&2
	exit 1
fi

if test -n "$1"; then
	echo "$arg0: $s is a $quo"
	exit 0
fi

case "$quo" in
	link)
		echo "$arg0: remove link $s, create dir $t" >&2
		rm -vf "$s"
		mkdir -p "$s"
		;;
	dir)
		echo "$arg0: remove dir $t, create link $s" >&2
		rm -rvf "$s"
		ln -sf "$t" "$s"
		;;
esac
