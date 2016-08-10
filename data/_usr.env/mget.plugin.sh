#
# Copyright 2015-2016 (c) Yousong Zhou
#
# Test
#
#	python -c 'd="".join(chr(i&0xff) for i in range(1024)); f=open("1024B", "wb"); f.write(d); f.close()'
#
# - test: download 1024B file in 1024 chunks
#
mget_url_file_size() {
	local url="$1"
	local size

	size="$(wget --spider "$url" 2>&1 | grep 'Length:' | cut -d ' ' -f 2)"

	if [ -n "$size" -a "$size" -ge 0 ]; then
		echo "$size"
	fi
}

_mget_chunk() {
	local url="$1"
	local total="$2"
	local outn="$3"
	local chunk="$4"
	local offset="$5"
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
	wget --tries=5 --no-verbose --start-pos="$startpos" -O- "$url" | \
		head -c "$remaining" >>"$outn" 2>/dev/null &
	_MGET_PIDS="$_MGET_PIDS $!"
}

_mget_total_chunk_fixup() {
	local url="$1"
	local count="$2"
	local total chunk fixup

	total="$(mget_url_file_size "$url")" || {
		__errmsg "mget: cannot get download size of $url"
		return 1
	}
	chunk="$(($total / $count))"
	fixup="$(($total - $chunk * $count))"

	echo $total $chunk $fixup
}

_mget_usage() {
	cat >&2 <<EOF
usage: mget <url> <count>

Open multiple wget to download <url>.  Each downloaded chunk will be named with
suffix .N with N starting from 1, ending with <count>

TODO:

- allow specifying index to download
- check chunk size on quit
- allow for specifying basename

EOF
}

mget() {
	local url="$1"
	local count="$2"
	local bunch total chunk
	local out width
	local i pos _chunk suffix

	if [ "$#" -ne 2 ]; then
		_mget_usage
		return 1
	fi

	# prefix for output filename
	out="$(basename "$url" | cut -f1 -d '?')"
	width="${#count}"

	# 'read' cannot be used in pipe because bash will consider execute it in
	# subshell thus the result is not available to caller
	bunch="$(_mget_total_chunk_fixup "$url" "$count")"
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
		_mget_chunk "$url" "$total" "$out.$suffix" "$_chunk" "$pos"
		pos="$(($pos + $_chunk))"
		i="$(($i + 1))"
	done
	wait
}
