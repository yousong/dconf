# golang
_go_path_match() {
	local dir="$1"

	if [ "${dir#$PREFIX_USR/go/}" != "$dir" ]; then
		return 0
	else
		return 1
	fi
}

# list absolute pathes to goroot
go_list() {
	echo "$PREFIX_USR/go/goroot-"* \
			| tr ' ' '\n' \
			| sort --version-sort --reverse
}

# select and make permanent the selection
#
# The priority of version source to be consulted:
#
#  1. $1 arg
#  2. content of $PREFIX_USR/go/.gover
#  3. the most recent version of go_list
#
go_select() {
	local ver="$1"
	local q="$2"
	local gover="$PREFIX_USR/go/.gover"
	local goroot

	if [ ! -d "$PREFIX_USR/go" ]; then
		return 1
	fi
	[ -n "$ver" ] || ver="$(cat "$gover" 2>/dev/null)"
	if [ -z "$ver" ]; then
		goroot="$(go_list | head -n1)"
		ver="${goroot##*-}"
	else
		goroot="$PREFIX_USR/go/goroot-$ver"
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
	export GOROOT="$PREFIX_USR/go/goroot-$ver"
	export GOPATH="$HOME/go"

	# clear out other "$PREFIX_USR/go" subdirs in PATH
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
