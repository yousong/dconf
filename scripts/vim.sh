#!/bin/bash -e

. "$TOPDIR/env.sh"

bundle_dir="$o_homedir/.vim/bundle"

__vimrc_files="
	$o_homedir/.vimrc
	$o_homedir/.vimrc.plugins
	$o_homedir/.vimrc.basic
"

__vim_foreach_patchdir() {
	find "$PATCH_DIR/_vim" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
}

__vim_handle_ycm() {
	local wd="$bundle_dir/YouCompleteMe"
	local donefile="$wd/.dconf_done_202401102014"
	[ -d "$wd" ] || return 0
	[ ! -f "$donefile" ] || return 0

	# Installation is done mainly by third_party/ycmd/build.py
	#
	# Binaries were downloaded from https://dl.bintray.com/ycm-core .
	# Version numbers are hardcoded in the build.py script.  Note that the
	# downloaded version may require newer versions of libc and cannot be
	# run on systems like CentOS 7.  In this case we can use
	# bundle-libraries.sh
	#
	#	docker run --name dev -v $PWD:/code -it debian:9 /bin/bash
	#	cat >/etc/apt/sources.list <<-EOF
	#		deb http://mirrors.aliyun.com/debian/ stretch main non-free contrib
	#		deb-src http://mirrors.aliyun.com/debian/ stretch main non-free contrib
	#		deb http://mirrors.aliyun.com/debian-security stretch/updates main
	#		deb-src http://mirrors.aliyun.com/debian-security stretch/updates main
	#		deb http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib
	#		deb-src http://mirrors.aliyun.com/debian/ stretch-updates main non-free contrib
	#		deb http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib
	#		deb-src http://mirrors.aliyun.com/debian/ stretch-backports main non-free contrib
	#	EOF
	#	apt update
	#	apt install -y file curl zip build-essential
	#	u='https://git.openwrt.org/?p=openwrt/staging/yousong.git;a=blob_plain;f=scripts/bundle-libraries.sh;hb=refs/heads/bundle-libraries'
	#	curl -o bundle-libraries.sh "$u"
	#	chmod a+x bundle-libraries.sh
	#	./bundle-libraries.sh clangd.d/ clangd
	#	#tar cJf clangd.tar.xz .clangd.bin clangd clangd.d/
	#
	# Dependencies are put in its own subdirectory in
	# third_party/ycmd/third_party
	#
	# ycmd now uses C++17 and requires at least GCC 8 to compile.  Or
	# checkout branch "legacy-c++11" and manually download clangd from
	#
	# 	https://github.com/clangd/clangd/releases/latest
	#
	# , and put the binary inside ycmd clangd thirdparty output bin
	#
	# ycmd build.py invokes cmake for building.  It will parse and pass
	# args from environment variable CMAKE_EXTRA_ARGS to cmake.
	#
	# Arguments
	#
	#   --all			enable all completer
	#   --clangd-completer		clangd
	#   --go-completer		"go build" local gopls copy
	#   --ts-completer		tsserver
	#   --rust-completer		rust, it will installl
	#
	#   --skip-build		skip building ycm_core
	#
	# We use sudo command to run as another user when doing "docker build".
	# ycmd b4cbf5696 ("Discourage running build.py with sudo, as it causes
	# permission issues").  Using --force-sudo may cause old revision to
	# fail for unrecognized argument
	local ycm_install_donefile="$wd/install_donefile_202401102027"
	if ! test -e "$ycm_install_donefile"; then
		env -u SUDO_COMMAND \
			"$wd/install.py" \
			--clangd-completer \
			--rust-completer \
			--ts-completer \
			$DCONF_VIM_YCM_INSTALL_ARGS \

		touch "$ycm_install_donefile"
	fi

	local ycmd_3rdparty="$wd/third_party/ycmd/third_party/"
	rm -rf "$ycmd_3rdparty/rust-analyzer/share/doc/"
	rm -rf "$ycmd_3rdparty/clangd/cache/"

	local ycm_clangd="$ycmd_3rdparty/clangd/output/bin/clangd"
	if ! "$ycm_clangd" --version >/dev/null; then
		local clangd="$(echo $o_homedir/.usr/toolchain/llvm-*/bin/clangd \
					| sort --version-sort --reverse \
					| head -n 1)"
		if "$clangd" --version >/dev/null; then
			if [ ! -e "$ycm_clangd.ycm" ]; then
				mv "$ycm_clangd" "$ycm_clangd.ycm"
			fi
			ln -sf "$clangd" "$ycm_clangd"
		fi
	fi
	local lsp_server_dir="$wd/lsp-server"
	mkdir -p "$lsp_server_dir"

	local serve_d_ver=0.7.6
	local dcd_ver=0.15.2
	if ! "$lsp_server_dir/serve-d" -v 2>&1 | grep -F "$serve_d_ver"; then
		local osa osn
		if test "$(uname -m)" = x86_64; then
			osa=x86_64
			case "$(uname -s)" in
				Linux) osn=linux ;;
				Darwin) osn=osx ;;
			esac
		fi
		if test -n "$osn"; then
			local tempd
			tempd="$(mktemp -d serve_d-XXX)"
			(
				local d="$lsp_server_dir/d"
				mkdir -p "$d"

				cd "$tempd"
				wget -O serve-d.tar.xz "https://github.com/Pure-D/serve-d/releases/download/v$serve_d_ver/serve-d_$serve_d_ver-$osn-$osa.tar.xz"
				tar xJf serve-d.tar.xz
				mv serve-d "$d"

				wget -O dcd.tar.gz "https://github.com/dlang-community/DCD/releases/download/v$dcd_ver/dcd-v$dcd_ver-$osn-$osa.tar.gz"
				tar xzf dcd.tar.gz
				mv dcd-client "$d"
				mv dcd-server "$d"
			)
			rm -rf "$tempd"
		else
			__notice "skip installing serve-d for $(uname -s) $(uname -m)"
		fi
	fi

	touch "$donefile"
}

__vim_bundle_ref() {
	local name="$1"

	case "$name" in
		vim-go)
			# https://github.com/fatih/vim-go/commit/6adc82bfef7f9a4b0db78065ae51b8ebb145c355
			# As of 2025-02-18, the most recent tag action (v1.28)  happens at 2022-12-18
			#
			# 2024-12-27
			echo 6adc82bfef7f9a4b0db78065ae51b8ebb145c355;;
		ctrlp.vim) echo "1.81" ;;
		#YouCompleteMe)
			# 2020/09/20 6d877784 ("Resolve completions on-demand")
			# bumps minimal vim version requirement from 7.4.1578
			# to 8.1.2269
			#
			# 2020/11/13 604a2a02 ("Update the ycmd submodule")
			# the merge bumps gcc version requirement from 4.8 to 8
			#
			# Revision before the bump
			#echo 4e480a317d4858db91631c14883c5927243d4893
			#;;
		*) echo "refs/remotes/origin/HEAD" ;;
	esac
}

config() {
	local f dataf
	local vundle_repo="$bundle_dir/Vundle.vim"
	local patchdir d name

	if ! vim --version &>/dev/null; then
		__notice "vim: skipped because vim was not found"
		return
	fi

	if [ ! -d "$vundle_repo/.git" ]; then
		git clone https://github.com/gmarik/Vundle.vim.git "$vundle_repo"
	fi

	for f in $__vimrc_files; do
		dataf="${f##*/.}"
		dataf="$DATA_DIR/_$dataf"
		if [ -f "$dataf" ]; then
			cp "$dataf" "$f"
		fi
	done

	__notice "vim: Installing Vundle packages, this may take a while."
	vim +BundleInstall +qa

	for patchdir in `__vim_foreach_patchdir`; do
		name="${patchdir##*/}"
		d="$bundle_dir/$name"
		if [ -d "$d" ]; then
			local ref
			ref="$(__vim_bundle_ref "$name")"

			cd "$d"
			if ! git rev-parse "$ref" &>/dev/null; then
				__info "vim: fetching $d"
				git fetch origin --tags
			fi
			git checkout -B dconf "$ref"

			__info "vim: patching $d"
			git am "$patchdir"/*
		fi
	done

	__vim_handle_ycm
}

collect() {
	local f dataf

	for f in $__vimrc_files; do
		if [ -f "$f" ]; then
			dataf="${f##*/.}"
			dataf="$DATA_DIR/_$dataf"
			cp "$f" "$dataf"
		fi
	done
}

refresh_patches() {
	local patchdir d name

	for patchdir in `__vim_foreach_patchdir`; do
		name="${patchdir##*/}"
		d="$bundle_dir/$name"
		if [ -d "$d" ]; then
			rm -vf "$patchdir"/*
			format_patch "$d" "$patchdir" "$(__vim_bundle_ref "$name")"..dconf
		fi
	done
}
