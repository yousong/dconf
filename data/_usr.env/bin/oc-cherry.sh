#!/usr/bin/env bash

branches="
3.0
2.14
2.13
2.12
2.11
2.10.0
"

if test "$#" -lt 2; then
	echo "usage: $(basename "$0") <prn> <til>" >&2
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


for b in $branches; do
	./scripts/cherry_pick_pull.sh "upstream/release/$b" "$prn"
	if test "$b" = "$til"; then
		break
	fi
done
