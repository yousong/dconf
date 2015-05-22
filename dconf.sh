#!/bin/sh -e

# available actions are
#  - config
#  - collect
action="$1"

[ -z "$action" ] && {
	echo "Usage: $(basename $0) <action>"  >&2
	exit 1
} || {
	true
}

INCLUDE_ONLY=1
. "$PWD/env.sh"
export TOPDIR

for script in "$SCRIPT_DIR"/*; do
	sh -e -c ". '$TOPDIR/env.sh'; _do '$script' '$action'"
done
