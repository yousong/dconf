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

dl_linux() {
	local ver="$1"
	local oIFS="$IFS"; IFS="."; set -- $ver; IFS="$oIFS"
	local ver_maj="$1"
	local ver_min="$2"
	local subdir fn
	local u urls

	if [ -z "$ver_maj" -o -z "$ver_min" ]; then
		__errmsg "dl_linux usage examples:"
		__errmsg "  dl_linux 1.0"
		__errmsg "  dl_linux 4.4.49"
		return 1
	fi
	if [ "$ver_maj" -ge 3 ]; then
		subdir="v$ver_maj.x"
	else
		subdir="v$ver_maj.$ver_min"
	fi
	fn="linux-$ver.tar.xz"
	urls="
http://mirrors.ustc.edu.cn/kernel.org/linux/kernel/$subdir/$fn
http://mirrors.aliyun.com/linux-kernel/$subdir/$fn
"

	for u in $urls; do
		wget -O "$fn" -c "$u" && break
	done
}

openwrt_repo_dir=

# Run this from inside OpenWrt/LEDE sub-project repo <currepo>.
#
# It will prepare commits in range origin/master..HEAD as patches and moves
# them into predefined patches/ subdir in <currepo>/../lede
#
# NOTE: old patches already present in target patches/ dir will be all deleted
openwrt_genpatch() {
	local def='
name=libubox;pkgdir=package/libs/libubox
name=procd;pkgdir=package/system/procd
name=ubox;pkgdir=package/system/ubox
'
	local currepo
	local curname
	local name dir
	local patchdir fn
	local line

	currepo="$(git rev-parse --show-toplevel)"
	if [ -z "$currepo" ]; then
		return 1
	fi
	if [ -z "$openwrt_repo_dir" ]; then
		openwrt_repo_dir="$(readlink -f "$currepo/../lede")"
	fi
	if [ ! -d "$openwrt_repo_dir" ]; then
		__errmsg "openwrt_repo_dir $openwrt_repo_dir does not exist"
		return 1
	fi
	curname="$(basename "$currepo")"
	for line in $def; do
		eval $line
		if [ "$name" = "$curname" ]; then
			patchdir="$openwrt_repo_dir/$pkgdir/patches"
			for fn in $(ls "$patchdir"); do
				rm -vf "$patchdir/$fn"
			done
			mkdir -p "$patchdir"
			git format-patch --signoff --output-directory="$patchdir" origin/master..HEAD
		fi
	done
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
