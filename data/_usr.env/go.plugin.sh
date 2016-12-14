# golang
_gover=1.7.4

_go_path_match() {
	local dir="$1"

	if [ "${dir#$PREFIX_USR/go/}" != "$dir" ]; then
		return 0
	else
		return 1
	fi
}

go_select() {
	local ver="${1:-$_gover}"
	local q="$2"
	local goroot="$PREFIX_USR/go/goroot-$ver"
	local d

	if [ ! -d "$goroot" ]; then
		if [ -z "$q" ]; then
			__errmsg "$goroot does not exist"
		fi
		return 1
	fi
	export GOROOT="$PREFIX_USR/go/goroot-$ver"
	export GOPATH="$PREFIX_USR/go/gopath-$ver"
	path_ignore_match PATH _go_path_match
	path_prepend PATH "$GOROOT/bin"
	path_prepend PATH "$GOPATH/bin"
}
