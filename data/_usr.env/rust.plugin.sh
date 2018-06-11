_rust_path_match() {
	local dir="$1"

	if [ "${dir#$o_usr/rust/}" != "$dir" ]; then
		return 0
	else
		return 1
	fi
}

rust_select() {
	local ver="$1"
	local q="$2"
	local rustroot

	if [ ! -d "$o_usr/rust" ]; then
		return 1
	fi
	if [ -z "$ver" ]; then
		rustroot="$(echo "$o_usr/rust/"*)"
		rustroot="${rustroot##* }"
		ver="${rustroot##*-}"
	else
		rustroot="$o_usr/rust/rustroot-$ver"
	fi
	if [ ! -d "$rustroot" ]; then
		if [ -z "$q" ]; then
			__errmsg "$rustroot does not exist"
		fi
		return 1
	fi
	path_ignore_match PATH _rust_path_match
	path_ignore_match MANPATH _rust_path_match
	path_action PATH prepend "$rustroot/bin"
	path_action MANPATH prepend "$rustroot/share/man"
}
