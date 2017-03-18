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
	local outn="$1"; shift
	local chunk="$1"; shift
	local offset="$1"; shift
	local bin
	local existing startpos remaining

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

_mget_usage() {
	cat >&2 <<EOF
usage: mget [options] --url <url> --count <count>

Open multiple <cmd> to download <url>.  Each downloaded chunk will be named
with suffix .N with N starting from 1, ending with <count>

 --cmd <cmd>        command to do the fetch (default to wget)
 --output <fn>      filename prefix (default to url basename)
 --pos-start <int>  zero-based start position (default to 0)
 --pos-end <int>    non-inclusive end position (default to Content-Length)
 -h|--help          show this help text

Examples

    mget --count 32 \\
        --cmd 'curl --location --socks5-hostname localhost:1080' \\
        --url http://example.com/f.200M

EOF
}

_mget_chunk_done() {
	local outn="$1"; shift
	local chunk="$1"; shift
	local existing

	if [ ! -f "$outn" ]; then
		return 2
	else
		existing="$(stat -c "%s" "$outn")"
		if [ "$existing" -eq "$chunk" ]; then
			return 0
		elif [ "$existing" -lt "$chunk" ]; then
			return 1
		else
			return 3
		fi
	fi
}

_mget_all_chunk_done() {
	local pos width i suffix
	local _chunk _fixup
	local rc

	_fixup="$mget_fixup"
	pos="$mget_pos_start"
	width="${#mget_count}"
	i=1
	while [ "$pos" -lt "$mget_pos_end" ]; do
		suffix="$(printf "%0${width}d" "$i")"
		if [ "$_fixup" -gt 0 ]; then
			_chunk="$(($mget_chunk + 1))"
			_fixup="$(($_fixup - 1))"
		else
			_chunk="$mget_chunk"
		fi

		_mget_chunk_done "$mget_output.$suffix" "$_chunk"
		rc="$?"; [ "$rc" = 0 ] || return "$rc"

		pos="$(($pos + $_chunk))"
		i="$(($i + 1))"
	done
}

mget() {
	local _chunk _fixup
	local pos width i suffix

	mget_count=
	mget_cmd=
	mget_output=
	mget_url=
	mget_pos_start=0
	mget_pos_end=
	mget_total=
	mget_chunk=
	mget_fixup=
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
			--pos-start)
				mget_pos_start="$2"
				shift 2
				;;
			--pos-end)
				mget_pos_end="$2"
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

	if [ -z "$mget_pos_end" ]; then
		mget_pos_end="$(_mget_url_file_size "$mget_cmd" "$mget_url")" || {
			__errmsg "mget: cannot get download size of $mget_url"
			return 1
		}
	fi
	if [ "$mget_pos_start" -gt "$mget_pos_end" ]; then
		__errmsg "mget: position invalid: $mget_pos_start->$mget_pos_end"
		return 1
	fi
	# 'read' cannot be used in pipe because it will be executed in subshell
	# thus the result is not available to caller
	mget_total="$(($mget_pos_end - $mget_pos_start))"
	mget_chunk="$(($mget_total / $mget_count))"
	mget_fixup="$(($mget_total - $mget_chunk * $mget_count))"

	# sh must be used because zsh has shwordsplit off
	_MGET_PIDS=''
	trap 'trap - INT; sh -c "kill $_MGET_PIDS"' INT

	_fixup="$mget_fixup"
	pos="$mget_pos_start"
	width="${#mget_count}"
	i=1
	while [ "$pos" -lt "$mget_pos_end" ]; do
		suffix="$(printf "%0${width}d" "$i")"
		if [ "$_fixup" -gt 0 ]; then
			_chunk="$(($mget_chunk + 1))"
			_fixup="$(($_fixup - 1))"
		else
			_chunk="$mget_chunk"
		fi
		_mget_chunk "$mget_cmd" "$mget_url" "$mget_output.$suffix" "$_chunk" "$pos"
		pos="$(($pos + $_chunk))"
		i="$(($i + 1))"
	done
	wait
	trap - INT

	_mget_all_chunk_done
}
