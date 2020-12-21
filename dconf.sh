#!/bin/sh -e

# available actions are
#  - config
#  - collect
action="$1"

if [ -z "$action" ]; then
	echo "Usage: $(basename $0) <action>"  >&2
	exit 1
fi

binsh="$(readlink -f /bin/sh)"
if [ "${binsh##*/}" = dash ]; then
	# Dash does not support ${var//pattern/repl}
	# Dash does not support &>/dev/null
	echo "dash as /bin/sh is not supported" >&2
	exit 1
fi

INCLUDE_ONLY=1
. "$PWD/env.sh"
export TOPDIR

for script in "$SCRIPT_DIR"/*; do
	sh -e -c ". '$TOPDIR/env.sh'; _do '$script' '$action'"
done
