# golang
_go_path_match() {
	local dir="$1"

	if [ "${dir#$o_usr/go/}" != "$dir" ]; then
		return 0
	else
		return 1
	fi
}

# list absolute pathes to goroot
go_list() {
	echo "$o_usr/go/goroot-"* \
			| tr ' ' '\n' \
			| sort --version-sort --reverse
}

# select and make permanent the selection
#
# The priority of version source to be consulted:
#
#  1. $1 arg
#  2. content of $o_usr/go/.gover
#  3. the most recent version of go_list
#
go_select() {
	local ver="$1"
	local q="$2"
	local gover="$o_usr/go/.gover"
	local goroot

	if [ ! -d "$o_usr/go" ]; then
		return 1
	fi
	[ -n "$ver" ] || ver="$(cat "$gover" 2>/dev/null)"
	if [ -z "$ver" ]; then
		goroot="$(go_list | head -n1)"
		ver="${goroot##*-}"
	else
		goroot="$o_usr/go/goroot-$ver"
	fi
	if [ ! -d "$goroot" ]; then
		if [ -z "$q" ]; then
			__errmsg "$goroot does not exist"
		fi
		return 1
	fi
	# https://golang.org/doc/go1compat
	#
	#	> Compatibility is at the source level. Binary compatibility for compiled
	#	> packages is not guaranteed between releases. After a point release, Go
	#	> source will need to be recompiled to link against the new release.
	#
	# https://groups.google.com/forum/#!topic/golang-nuts/TUyhyFeX0ig
	#
	#	> There is no compatibility for compiled packages between different
	#	> versions of go
	#
	# That's why we need to rebuild $GOPATH when changing go version.  The bad
	# thing is that "go install '...'" can fail prematurely by bad packages.
	# Remove $GOPATH/pkg is a safe measure to do
	export GOROOT="$o_usr/go/goroot-$ver"
	export GOPATH="$HOME/go"

	# clear out other "$o_usr/go" subdirs in PATH
	path_ignore_match PATH _go_path_match
	path_action PATH prepend "$GOROOT/bin"
	path_action PATH prepend "$GOPATH/bin"
	echo "$ver" >"$gover"
}

go_get() {
	local group="$1"

	case "$group" in
		grpc)
			go get -u google.golang.org/grpc
			go get -u github.com/golang/protobuf/protoc-gen-go
			;;
		etcd)
			go get -u github.com/coreos/etcd/cmd/etcd
			go get -u github.com/coreos/etcd/cmd/etcdctl
			;;
		*)
			go get "$@"
	esac
}

cgo_env() {
	export PKG_CONFIG_PATH="$o_usr/lib/pkgconfig:$o_usr/share/pkgconfig"

	# The following is for flags in the source code, security limitations
	# do not apply to flags from environment variables
	#
	#export CGO_CFLAGS_ALLOW='.*'
	#export CGO_CFLAGS_DISALLOW='.*'

	# cgo will be enabled by default for native build.  When doing cross
	# compilation, there are at least 3 methods to specify the c/cxx
	# compiler to use.
	#
	#export CGO_ENABLED=1
	#export CC_FOR_TARGET=triplet-cc
	#export CC_FOR_linux_arm=triplet-cc
	#export CC=triplet-cc

	# Better if packages use "cgo pkg-config: libnl-3.0 libnl-genl-3.0"
	#
	#export CGO_CFLAGS="-g -O2"
	export CGO_CPPFLAGS="-I$o_usr/include/libnl3 -I$o_usr/include"
	export CGO_LDFLAGS="-g -O2 -L$o_usr/lib -Wl,-rpath,$o_usr/lib -lnl-3 -lnl-genl-3"
}
