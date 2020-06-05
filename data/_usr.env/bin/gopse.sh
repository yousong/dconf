#!/usr/bin/env bash
#
# This outputs golang module pseudo version string for the specified git repo
# ref (HEAD by default).  See "Pseudo-version" section in output of "go help
# modules" for more details
#

ref="${1:-HEAD}"

tri="$(git rev-list --pretty='%ct %H' --date=short -1 "$ref" | tail -n1)"
set -- $tri

ts=$1
ts="$(TZ=UTC date +%Y%m%d%H%M%S --date=@$ts)"

ch=$2
ch="${ch:0:12}"

echo "v0.0.0-$ts-$ch"
