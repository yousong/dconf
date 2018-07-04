_toolchain_path_match() {
	local dir="$1"

	if [ "${dir#$o_usr/toolchain/}" != "$dir" ]; then
		return 0
	else
		return 1
	fi
}

toolchain_list() {
	echo "$o_usr/toolchain/"* \
			| tr ' ' '\n' \
			| sort --version-sort --reverse
}

toolchain_select() {
	local name="$1"
	local basedir="$o_usr/toolchain/$name"

	if [ ! -d "$basedir" ]; then
		__errmsg "$basedir does not exist"
		return 1
	fi

	toolchain_clear
	path_action PATH prepend "$basedir/bin"
}

# clear out other "$o_usr/toolchain" subdirs in PATH
toolchain_clear() {
	path_ignore_match PATH _toolchain_path_match
}
