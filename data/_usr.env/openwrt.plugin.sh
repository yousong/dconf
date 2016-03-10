openwrt_build_current() {
	local prefix="$HOME/.usr"
	local lua_path="$prefix/lib/lua/5.1"
	local build_dir="_t"

	mkdir -p "$prefix"
	rm -rf "$build_dir"
	mkdir -p "$build_dir"

	cd "$build_dir";
	CFLAGS="-g3 -I$prefix/include -isystem=$prefix"	\
	LDFLAGS="-L$prefix/lib -Wl,-rpath,$prefix/lib"	\
		cmake -DCMAKE_PREFIX_PATH="$prefix"			\
		-DCMAKE_INSTALL_PREFIX="$prefix"			\
		-DLUAPATH="$lua_path" ..					\
			&& make
	cd ..
}

# Make --to xx --cc arguments for git-send-email from output of
# get_maintainer.pl script.
#
#   to_maintainers 133-MIPS-UAPI-Fix-unrecognized-opcode-WSBH-DSBH-DSHD-whe.patch
to_maintainers() {
	local f="$1"
	local get_maintainer="./scripts/get_maintainer.pl"
	local raw
	local to cc

	[ -x "$get_maintainer" ] || {
		echo "Cannot find executable $get_maintainer" >&2
		return 1
	}

	raw="$("$get_maintainer" "$f")"
	raw="$(echo "$raw" | cut -f1 -d'(')"
	to="$(echo "$raw" | head -n  1 | sed 's/^\(.*\)\s\+/--to "\1" /' | tr -d '\n')"
	cc="$(echo "$raw" | tail -n +2 | sed 's/^\(.*\)\s\+/--cc "\1" /' | tr -d '\n')"

	echo "$to $cc"
}
