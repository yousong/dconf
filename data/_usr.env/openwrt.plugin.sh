openwrt_build_current() {
	local prefix="$HOME/.usr"
	local lua_path="$prefix/lib/lua5.1"
	local build_dir="_t"

	mkdir -p "$prefix"
	rm -rf "$build_dir"
	mkdir -p "$build_dir"

	cd "$build_dir";
	CFLAGS="-g3 -I$prefix/include -I$prefix/include/lua5.1 -isystem=$prefix"	\
	LDFLAGS="-L$prefix/lib -Wl,-rpath,$prefix/lib"	\
		cmake -DCMAKE_PREFIX_PATH="$prefix"			\
		-DCMAKE_INSTALL_PREFIX="$prefix"			\
		-DLUAPATH="$lua_path" ..					\
			&& make VERBOSE=1
	cd ..
}

openwrt_planwan() {
	local cmds
	cmds="
	ip netns del lan0
	ip netns del wan0

	set -x

	ip netns add lan0
	ip link add lan0 type veth peer name plan0
	ip link set plan0 master br-lan up
	ip link set lan0 netns lan0 up
	ip netns exec lan0 bash -c '
	  ip addr add 192.168.1.99/24 dev lan0
	  ip route add 0.0.0.0/0 via 192.168.1.1 dev lan0
	'

	ip netns add wan0
	ip link add wan0 type veth peer name pwan0
	ip link set pwan0 master br-wan up
	ip link set wan0 netns wan0 up
	ip netns exec wan0 bash -c '
	  ip addr add 192.168.7.99/24 dev wan0
	  ip route add 0.0.0.0/0 via 192.168.7.84 dev wan0
	  bash
	'
	"
	if [ -z "$openwrt_planwan_confirmed" ]; then
		__errmsg "planwan: about to run commands with sudo"
		__errmsg "planwan: confirm or ctrl-c to abort"
		read
	fi
	sudo true
	sudo bash -x -c "$cmds"
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

dl_gnu() {
	local proj="$1"; shift
	local ver="$1"; shift
	local fpath

	case "$proj" in
		gcc) fpath="gcc/gcc-$ver/gcc-$ver.tar.xz";;
		*)   fpath="$proj/$proj-$ver.tar.xz" ;;
	esac
	wget -c "http://mirrors.ustc.edu.cn/gnu/$fpath"
}

genpatches_usage() {
	__errmsg "genpatches r=rel-ref o=out-dir"
	__errmsg
	__errmsg "example usage: "
	__errmsg
	__errmsg "    genpatches r=v4.2.0 o=../openwrt/packages/utils/qemu/patches"
	__errmsg "    genpatches r=v4.2.0 o=../openwrt/packages/utils/qemu/patches ns=600 nw=3"
}

genpatches() {
	local r o
	local ns nw
	local v
	local fp fn

	for v in "$@"; do
		eval "$v"
	done

	if [ -z "$r" ]; then
		genpatches_usage
		return 1
	fi
	if [ -z "$o" ]; then
		genpatches_usage
		return 1
	fi
	[ "$ns" -gt 1 ] || ns=1
	[ "$nw" -gt 0 ] || nw=4

	mkdir -p "$o"

	local i="$ns"
	git rev-list --reverse "$r..HEAD" | while read v; do
		fp="$(git format-patch \
			-1 \
			--start-number "$i" \
			--output-directory "$o/" \
			$v 2>&1)"
		fn="$(basename "$fp")"
		n="${fn%%-*}"
		while [ "${#n}" -gt "$nw" ]; do
			n="${n#?}"
		done
		mv "$fp" "$(dirname "$fp")/${n}-${fn#*-}"
		i=$((i+1))
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
