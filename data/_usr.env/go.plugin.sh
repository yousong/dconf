# golang
_go_path_match() {
	local dir="$1"

	if [ "${dir#$PREFIX_USR/go/}" != "$dir" ]; then
		return 0
	else
		return 1
	fi
}

go_select() {
	local ver="$1"
	local q="$2"
	local goroot

	if [ ! -d "$PREFIX_USR/go" ]; then
		return 1
	fi
	if [ -z "$ver" ]; then
		goroot="$(echo "$PREFIX_USR/go/goroot-"*)"
		goroot="${goroot##* }"
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
	# That's why $GOPATH needs to have a full $ver spec, not only part of it
	export GOROOT="$PREFIX_USR/go/goroot-$ver"
	export GOPATH="$PREFIX_USR/go/gopath-$ver"
	path_ignore_match PATH _go_path_match
	path_prepend PATH "$GOROOT/bin"
	path_prepend PATH "$GOPATH/bin"
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
