openwrt_build_current() {
	local prefix="$HOME/.usr"
	local lua_path="$prefix/lib/lua/5.2"
	local build_dir="_t"

	mkdir -p "$prefix"
	rm -rf "$build_dir"
	mkdir -p "$build_dir"

	cd "$build_dir";
	CFLAGS="-g3 -I$prefix/include"					\
	LDFLAGS="-L$prefix/lib"						\
		cmake -DCMAKE_PREFIX_PATH="$prefix"		\
		-DCMAKE_INSTALL_PREFIX="$prefix"		\
		-DLUAPATH="$lua_path" ..				\
			&& make all install
	cd ..
}
