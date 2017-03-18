#
# Copyright 2015-2017 (c) Yousong Zhou
#
# Test
#
#	python -c 'd="".join(chr(i&0xff) for i in range(1024)); f=open("1024B", "wb"); f.write(d); f.close()'
#
# - test: download 1024B file in 1024 chunks
#
_mget_chunk() {
	local cmd="$1"; shift
	local url="$1"; shift
	local total="$1"; shift
	local outn="$1"; shift
	local chunk="$1"; shift
	local offset="$1"; shift
	local bin
	local existing startpos remaining

	# size of last chunk needs to be done right
	if [ "$(($offset + $chunk))" -gt "$total" ]; then
		chunk="$(($total - $offset))"
	fi

	if [ ! -f "$outn" ]; then
		startpos="$offset"
		remaining="$chunk"
	else
		existing="$(stat -c "%s" "$outn")"
		if [ "$existing" -eq "$chunk" ]; then
			return 0
		elif [ "$existing" -gt "$chunk" ]; then
			return 255
		fi
		startpos="$(($offset + $existing))"
		remaining="$(($chunk - $existing))"
	fi

	__errmsg "mget: $outn: size $remaining from $startpos to $(($startpos + $remaining))"
	bin="$(_mget_bin_type $cmd)"
	case "$bin" in
		wget)
			$cmd --tries=5 --no-verbose --start-pos="$startpos" -O- "$url" \
				| head -c "$remaining" \
				>>"$outn" 2>/dev/null &
			;;
		curl)
			$cmd --retry 5 --silent --range "$startpos-$(($startpos+$remaining-1))" "$url" \
				>>"$outn" 2>/dev/null &
			;;
		*)
			return 1
			;;
	esac
	# this records only pid of last process in the pipe, i.e. `head' command in
	# the case of wget
	_MGET_PIDS="$_MGET_PIDS $!"
}

_mget_bin_type() {
	local cmd="$1"; shift

	set -- $cmd
	echo "${1##*/}"
}

_mget_url_file_size() {
	local cmd="$1"; shift
	local url="$1"; shift
	local bin
	local size

	bin="$(_mget_bin_type "$cmd")"
	case "$bin" in
		wget)
			size="$($cmd --spider "$url" 2>&1 | awk '/Length:/ { print $2 }')"
			;;
		curl)
			size="$($cmd --head --silent "$url" | awk '/Content-Length:/ { gsub(/[^0-9]/, "", $2); LEN=$2 } END { print LEN }')"
			;;
		*)
			return 1
			;;
	esac

	if [ -n "$size" -a "$size" -ge 0 ]; then
		echo "$size"
	else
		return 1
	fi
}

_mget_total_chunk_fixup() {
	local cmd="$1"; shift
	local url="$1"; shift
	local count="$1"; shift
	local total chunk fixup

	total="$(_mget_url_file_size "$cmd" "$url")" || {
		__errmsg "mget: cannot get download size of $url"
		return 1
	}
	chunk="$(($total / $count))"
	fixup="$(($total - $chunk * $count))"

	echo $total $chunk $fixup
}

_mget_usage() {
	cat >&2 <<EOF
usage: mget [-h|--help] [--cmd <cmd>] [--output <output-prefix>] --url <url> --count <count>

Open multiple <cmd> to download <url>.  Each downloaded chunk will be named
with suffix .N with N starting from 1, ending with <count>

Examples

	mget --count 32 \\
		--cmd 'curl --location --socks5-hostname localhost:1080' \\
		--url http://example.com/f.200M

TODO:

- allow specifying index to download
- check chunk size on quit
- allow for specifying basename

EOF
}

mget() {
	local mget_url
	local mget_count
	local mget_cmd
	local bunch total chunk
	local width
	local i pos _chunk suffix

	mget_count=
	mget_cmd=
	mget_output=
	mget_url=
	while true; do
		if [ -z "$1" ]; then
			break
		fi
		case "$1" in
			--url)
				mget_url="$2"
				shift 2
				;;
			--count)
				mget_count="$2"
				shift 2
				;;
			--cmd)
				mget_cmd="$2"
				shift 2
				;;
			--output)
				mget_output="$2"
				shift 2
				;;
			-h|--help)
				_mget_usage
				return 0
				;;
			*)
				__errmsg "unknown option: $1"
				_mget_usage
				return 1
				;;
		esac
	done
	if [ -z "$mget_url" -o -z "$mget_count" ]; then
		_mget_usage
		return 1
	fi
	if [ -z "$mget_cmd" ]; then
		mget_cmd=wget
	fi

	# prefix of output filename
	if [ -z "$mget_output" ]; then
		mget_output="$(basename "$mget_url" | cut -f1 -d '?')"
	fi
	width="${#mget_count}"

	# 'read' cannot be used in pipe because it will be executed in subshell
	# thus the result is not available to caller
	bunch="$(_mget_total_chunk_fixup "$mget_cmd" "$mget_url" "$mget_count")"
	total="${bunch%% *}"
	chunk="${bunch% *}"
	chunk="${chunk#* }"
	fixup="${bunch##* }"

	# sh must be used because zsh has shwordsplit off
	_MGET_PIDS=''
	trap 'trap - INT; sh -c "kill $_MGET_PIDS"' INT

	pos=0
	i=1
	while [ "$pos" -lt "$total" ]; do
		suffix="$(printf "%0${width}d" "$i")"
		if [ "$fixup" -gt 0 ]; then
			_chunk="$(($chunk + 1))"
			fixup="$(($fixup - 1))"
		else
			_chunk="$chunk"
		fi
		_mget_chunk "$mget_cmd" "$mget_url" "$total" "$mget_output.$suffix" "$_chunk" "$pos"
		pos="$(($pos + $_chunk))"
		i="$(($i + 1))"
	done
	wait
	trap - INT
}
