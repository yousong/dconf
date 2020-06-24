#!/usr/bin/env bash

branches="
3.3
3.2
3.1
3.0
2.13
2.12
2.11
2.10.0
"

if test "$#" -lt 2; then
	echo "usage: $(basename "$0") <til> <prn>" >&2
	exit 1
fi	

til="$1"; shift
prn="$1"; shift

for b in $branches; do
	if test "$b" = "$til"; then
		found=1
		break
	fi
done
if test -z "$found"; then
	echo "unknown branch $til" >&2
	exit 1
fi

cherries=(
	"$HOME/go/src/yunion.io/x/onecloud/scripts/cherry_pick_pull.sh"
	"./scripts/cherry_pick_pull.sh"
	"../onecloud/scripts/cherry_pick_pull.sh"
)

found=
for cherry in "${cherries[@]}"; do
	if test -x "$cherry"; then
		found=1
		break
	fi
done
if test -z "$found"; then
	echo "cannot find cherry picker" >&2
	exit 1
fi

for b in $branches; do
	"$cherry" "upstream/release/$b" "$prn"
	if test "$b" = "$til"; then
		break
	fi
done
