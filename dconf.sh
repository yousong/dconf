#!/bin/bash -e

# available actions are
#  - config
#  - collect
action="$1"

if [ -z "$action" ]; then
	echo "Usage: $(basename $0) <action>"  >&2
	exit 1
fi

INCLUDE_ONLY=1
. "$PWD/env.sh"
export TOPDIR

for script in "$SCRIPT_DIR"/*; do
	/bin/bash -e -c ". '$TOPDIR/env.sh'; _do '$script' '$action'"
done
