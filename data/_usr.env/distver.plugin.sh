distver_path_match_() {
	local dist="$1"; shift
	local dir="$1"; shift

	if [ "${dir#$o_usr/$dist/}" != "$dir" ]; then
		return 0
	else
		return 1
	fi
}

# list absolute pathes to distver root
distver_list() {
	local dists
	local dist
	if [ "$#" -eq 0 ]; then
		dists=(
			go
			jdk
			nginx
			rust
			toolchain
		)
	else
		dists=("$@")
	fi

	for dist in "${dists[@]}"; do
		find "$o_usr/$dist/" -mindepth 1 -maxdepth 1 -type d 2>/dev/null
	done \
		| tr ' ' '\n' \
		| sort --version-sort --reverse
}

# select and make permanent the selection
#
#  $1: name, dir name after "$o_usr/", e.g. go, rust, jdk
#  $2: ver, dirname after "$o_usr/$1/"
#  $3: quiet, stderr on non-existent "$o_usr/$1/$2"
#
# The priority of version source to be consulted:
#
#  1. $2 arg
#  2. content of $o_usr/$1/.ver
#  3. the most recent version of distver_list
#
distver_select_() {
	local dist="$1"; shift
	local ver="$1"; shift
	local q="$1"; shift
	local distroot="$o_usr/$dist"
	local distverf="$distroot/.ver"
	local distverroot

	if [ ! -d "$distroot" ]; then
		return 1
	fi
	[ -n "$ver" ] || ver="$(cat "$distverf" 2>/dev/null)"
	if [ -z "$ver" ]; then
		distverroot="$(distver_list "$dist" | head -n1)"
		ver="${distverroot##*/}"
	else
		distverroot="$distroot/$ver"
	fi
	if [ ! -d "$distverroot" ]; then
		if [ -z "$q" ]; then
			__errmsg "$distverroot does not exist"
		fi
		return 1
	fi
	echo "$ver" >"$distverf"
	if [ "$#" -gt 0 ]; then
		"$@" "$distverroot"
	fi
}

go_select_() {
	local distverroot="$1"; shift

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
	export GOROOT="$distverroot"

	path_ignore_match PATH distver_path_match_ go
	path_action PATH prepend "$GOROOT/bin"
}

go_select() {
	[ "$#" -gt 1 ] || set -- "$@" "" ""
	local ver="$1"; shift
	local q="$1"; shift

	distver_select_ go "$ver" "$q" go_select_
	if which go &>/dev/null; then
		export GOPROXY=https://goproxy.cn,https://proxy.golang.org,direct
		export GOPATH="$HOME/go"
		if [ -z "$GOROOT" -o ! -d "$GOROOT" ]; then
			unset GOROOT
			# go installed by package managers
			export GOROOT="$(go env GOROOT)"
		fi
		path_action PATH prepend "$GOPATH/bin"
	fi
}

go_install() {
	local ver="$1"
	local goos goarch

	if test -z "$ver"; then
		echo "Usage: go_install goVER" >&2
		echo "Usage: go_install go1.21.2" >&2
		return 1
	fi

	goos="$(go_os)"
	goarch="$(go_arch)"

	local f
	local u
	local d

	f="$ver.$goos-$goarch.tar.gz"
	u="https://go.dev/dl/$f"
	d="$HOME/.usr/go/"
	wget -c -O "$f" "$u"
	tar xzf "$f"
	mv go "$ver"
	mkdir -p "$d"
	mv "$ver" "$d"
	chmod -R a-w "$d/$ver"
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

rust_install() {
	cat <<EOF >&2
Download, run rustup-init, do initialzation

	curl https://sh.rustup.rs -sSf | md5sum # last check: e4a1377ff6ec10f37ed30963b1383ff5
	                                        # 2021/06/29: e0ee4d92a63afde5ab5210d355f9bbd6
	curl https://sh.rustup.rs -sSf | sh -s -- --help
	curl https://sh.rustup.rs -sSf | sh -s -- --no-modify-path --default-toolchain stable -y

Docs: https://rust-lang.github.io/rustup/concepts/profiles.html

Use rustup

	rustup self update
	rustup self uninstall
	rustup toolchain list
	rustup toolchain install nightly
	rustup toolchain install stable-gnu
	rustup toolchain uninstall nightly
	rustup update
	rustup default nightly
	rustup default stable
	rustup run nightly rustc --version
	rustup target list

	# it's rustup proxy calling toolchain cargo
EOF
}

rust_env_init() {
	export CARGO_HOME="$HOME/.cargo"

	# https://rust-lang.github.io/rustup/environment-variables.html
	export RUSTUP_HOME="$HOME/.rustup"
	# RUSTUP_UPDATE_ROOT can be used by https://sh.rustup.rs for fetching
	# rustup-init binary.  As of 2021/10/20, the url will be like
	# ${RUSTUP_UPDATE_ROOT}/dist/${_arch}/rustup-init${_ext}
	export RUSTUP_DIST_SERVER=https://mirrors.sjtug.sjtu.edu.cn/rust-static
	export RUSTUP_UPDATE_ROOT=https://mirrors.sjtug.sjtu.edu.cn/rust-static/rustup
	#export RUSTUP_DIST_SERVER="https://mirrors.ustc.edu.cn/rust-static"
	#export RUSTUP_UPDATE_ROOT="https://mirrors.ustc.edu.cn/rust-static/rustup"
	#export RUSTUP_DIST_SERVER="https://mirrors.tuna.tsinghua.edu.cn/rustup"
	#export RUSTUP_UPDATE_ROOT="https://mirrors.tuna.tsinghua.edu.cn/rustup/rustup"
	if [ -d "$CARGO_HOME/bin" ]; then
		path_action PATH prepend "$CARGO_HOME/bin"
	fi
	# rustc-docs is only available for tier1 targets
	#
	# rustup doc not working on m1 macbook,
	# https://github.com/rust-lang/rustup/issues/2692#issuecomment-848406797
	#
	# Wait till aarch64-apple-darwin becomes tier1 target,
	# https://doc.rust-lang.org/nightly/rustc/platform-support.html
	alias rustdoc="rustup +stable-x86_64-unknown-linux-gnu doc"
}

node_install() {
	cat <<EOF >&2
Bootstrap nodejs and n (nodejs version manager)

	curl -L https://raw.githubusercontent.com/tj/n/master/bin/n -o n
	export N_PREFIX="$o_usr"   # install to $o_usr/n/
	bash n lts                 # install latest nodejs LTS
	npm install -g n           # install n command to path

EOF
}

node_env_init() {
	export N_PREFIX=$o_usr
	export PNPM_HOME="$HOME/.local/share/pnpm"
	path_action PATH peek_append "$PNPM_HOME"
}

jdk_select_() {
	local distverroot="$1"; shift

	case "$(jdk_os)" in
		macos)
			export JAVA_HOME="$distverroot/Contents/Home"
			;;
		linux)
			export JAVA_HOME="$distverroot"
			;;
		*)
			return 1
			;;
	esac
	path_ignore_match PATH distver_path_match_ jdk
	path_action PATH prepend "$JAVA_HOME/bin"
}

jdk_select() {
	[ "$#" -gt 1 ] || set -- "$@" "" ""
	local ver="$1"; shift
	local q="$1"; shift

	distver_select_ jdk "$ver" "$q" jdk_select_
}

jdk_get_and_install() {
	local jdk_url="$1"; shift
	local jdk_src
	local sha256 sha256got

	sha256="$(curl -s "$jdk_url.sha256")"
	jdk_src="$(basename "$jdk_url")"

	mget --url "$jdk_url" --count 8
	sha256got="$(sha256sum "$jdk_src" | cut -f1 -d' ')"
	if [ "$sha256" != "$sha256got" ]; then
		__errmsg "$jdk_src: checksum mismatch"
		__errmsg "$jdk_src: checksum got  $sha256got"
		__errmsg "$jdk_src: checksum want $sha256got"
		return 1
	fi
	mkdir -p "$o_usr/jdk"
	tar -C "$o_usr/jdk" -xzf "$jdk_src"
}

jdk_arch() {
	case "$(uname -m)" in
		arm64) echo aarch64 ;;
		x86_64) echo x64 ;;
		*) return 1 ;;
	esac
}

jdk_os() {
	case "$(uname -s)" in
		Darwin) echo macos ;;
		Linux) echo linux ;;
		*) return 1 ;;
	esac
}

# OS identifier for archives of jdk 16 and earlier
jdk16_os() {
	case "$(uname -s)" in
		Darwin) echo osx ;;
		Linux) echo linux ;;
		*) return 1 ;;
	esac
}

jdk11_install() {
	local jdk_src="openjdk-11.0.2_$(jdk16_os)-x64_bin.tar.gz"
	local jdk_url="https://download.java.net/java/GA/jdk11/9/GPL/$jdk_src"
	jdk_get_and_install "$jdk_url"
}

jdk17_install() {
	local ver=17.0.2
	local jdk_src="openjdk-${ver}_$(jdk_os)-$(jdk_arch)_bin.tar.gz"
	local jdk_url="https://download.java.net/java/GA/jdk${ver}/dfd4a8d0985749f896bed50d7138ee7f/8/GPL/$jdk_src"
	jdk_get_and_install "$jdk_url"
}

jdk21_install() {
	local ver=21.0.1
	local jdk_src="openjdk-${ver}_$(jdk_os)-$(jdk_arch)_bin.tar.gz"
	local jdk_url="https://download.java.net/java/GA/jdk${ver}/415e3f918a1f4062a0074a2794853d0d/12/GPL/$jdk_src"
	jdk_get_and_install "$jdk_url"
}

jdk_install() {
	cat <<EOF
Install jre/jdk 8 from package managers

	sudo apt-get install openjdk-8-jre
	sudo apt-get install openjdk-8-jdk
	sudo yum install -y java-1.8.0-openjdk
	sudo yum install -y java-1.8.0-openjdk-devel

Install ready binaries for later versions

	jdk11_install
	jdk17_install
	jdk_get_and_install "URL"

- How to download and install prebuilt OpenJDK packages, https://openjdk.java.net/install/
- Ready for use, Early access, Reference implementations, https://jdk.java.net/
- Archived OpenJDK General-Availability Releases, https://jdk.java.net/archive/
- https://en.wikipedia.org/wiki/Java_(programming_language)#Versions
EOF
}

jdk_src_get() {
	cat <<EOF
Repo jdk8 is for OpenJDK8 initially.  Then jdk8u is used for post-release
updates to OpenJDK8.  Likely jdk8u-dev is for developement

URL layout of hg.openjdk.java.net

	http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/archive/3ab471c4760a.tar.bz2
				     |    |     |
				  project |     L subrepo
				    umbrella repo

	project: jdk6, jdk7, jdk8
	umbrella repo for build tools: jdk8u, jdk8u-dev
	subrepo: jdkcorba, hotspot, jaxp, jaxws, jdk, langtools, nashorn

The OpenJDK GitHub mirror repos however merges all subrepos into a single git repo

As of 2022/02/10

	#jdk8u131_b11=http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/archive/3ab471c4760a.tar.bz2
	jdk8u131_b11=https://github.com/openjdk/jdk8u/archive/refs/tags/jdk8u131-b11.tar.gz
	curl -vL -o jdk8u131_b11.src.tar.gz "\$jdk8u131_b11"

Source code is also available within jdk dir: \$JAVA_HOME/lib/src.zip

- jdk8u jdk tags, http://hg.openjdk.java.net/jdk8u/jdk8u/jdk/tags
- https://stackoverflow.com/questions/44097483/what-version-of-openjdk8s-source-do-i-get-to-build-update-131-same-as-oracles/44190647
EOF
}

toolchain_clear() {
	path_ignore_match PATH distver_path_match_ toolchain
}

toolchain_select_() {
	local distverroot="$1"; shift

	toolchain_clear
	path_action PATH prepend "$distverroot/bin"
}

toolchain_select() {
	[ "$#" -gt 0 ] || set -- "$@" "" ""
	local ver="$1"; shift

	distver_select_ toolchain "$ver" "" toolchain_select_
}

go_os() {
	case "$(uname -s)" in
		Darwin) echo darwin ;;
		Linux) echo linux  ;;
		*) __errmsg "unsupported system type: $(uname -s)"; return 1 ;;
	esac
}

go_arch() {
	case "$(uname -m)" in
		x86_64) echo amd64 ;;
		arm64) echo arm64  ;;
		*) __errmsg "unsupported machine type: $(uname -m)"; return 1 ;;
	esac
}

k8s_install() {
	local name="$1"; shift
	local goos goarch
	local github_mirror

	goos="$(go_os)"
	goarch="$(go_arch)"

	github_mirror="${GITHUB_MIRROR:-https://github.com}"
	#GITHUB_MIRROR="https://hub.fastgit.org"

	local u v
	case "$name" in
		helm)
			# Installing helm, https://helm.sh/docs/intro/install/
			u="https://get.helm.sh/helm-v3.7.1-${goos}-${goarch}.tar.gz"
			u="https://mirrors.huaweicloud.com/helm/v3.7.1/helm-v3.7.1-${goos}-${goarch}.tar.gz"
			;;
		kustomize)
			# Kustomize, https://kubectl.docs.kubernetes.io/installation/kustomize/binaries/
			u="$github_mirror/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.3.0/kustomize_v4.3.0_${goos}_${goarch}.tar.gz"
			;;
		kubectl)
			v=1.23.6 # curl -L -s https://dl.k8s.io/release/stable.txt
			case "$goos/$goarch" in
				linux/amd64)
					u="https://mirrors.aliyun.com/kubernetes/apt/pool/kubectl_${v}-00_${goarch}_69db18624912cf4b199e7e54b2e2dd24b01e7d2b4b61c5098843eefa79e252e0.deb"
					;;
				darwin/*|linux/*)
					u="https://dl.k8s.io/release/v$v/bin/$goos/$goarch/kubectl"
					;;
				*)
					__errmsg "no $goos support for kubectl at the moment"
					return 1
					;;
			esac
			;;
		kruise)
			u="$github_mirror/openkruise/kruise-tools/releases/latest/download/kubectl-kruise_${goos}_${goarch}"
			;;
		krew)
			# https://kubernetes.io/docs/tasks/extend-kubectl/kubectl-plugins/
			u="$github_mirror/kubernetes-sigs/krew/releases/latest/download/krew-${goos}_${goarch}.tar.gz"
			;;
		*)
			__errmsg "unexpected component: $name"
			return 1
			;;
	esac

	local kubebin="$HOME/.kube/bin"
	mkdir -p "$kubebin"

	local d
	d="$(find "$PWD" -maxdepth 1 -name "$name.???" -type d | head -n1)"
	if [ -z "$d" ]; then
		d="$(mktemp -d "$name.XXX")"
	fi
	case "$name" in
		helm|krew|kustomize)
			(
				cd "$d"
				wget -c -O "$name.tar.gz" "$u"
				tar xzf "$name.tar.gz"
				find . -name "$name" | xargs -I{} mv {} "$kubebin"
				cd ..
				rm -rvf "$d"
			)
			;;
		kubectl)
			(
				cd "$d"
				case "$goos" in
					linux)
						wget -c -O "$name.deb" "$u"
						ar x "$name.deb" data.tar.xz
						tar xJf data.tar.xz
						find . -name "$name" | xargs -I{} mv {} "$kubebin"
						;;
					darwin)
						wget -c -O "$name" "$u"
						chmod a+x "$name"
						mv "$name" "$kubebin"
						;;
				esac
				cd ..
				rm -rvf "$d"
			)
			;;
		kruise)
			(
				cd "$d"
				wget -c -O "kubectl-$name" "$u"
				chmod a+x "kubectl-$name"
				mv "kubectl-$name" "$kubebin"
				cd ..
				rm -rvf "$d"
			)
			;;
		*)
			__errmsg "unexpected component: $name"
			return 1
			;;
	esac
	# regns=registry.aliyuncs.com/google_containers/kube-apiserver
}

k8s_init() {
	local d="$HOME/.kube/bin"

	if [ -d "$d" ]; then
		path_action PATH prepend "$d"
	fi
}

bazel_init() {
	# https://github.com/bazelbuild/bazelisk#bazeliskrc-configuration-file
	#
	# .bazeliskrc is required to be at root directory of a workspace.
	# That's why the setting was done through environment variables
	export BAZELISK_BASE_URL=https://github.com/bazelbuild/bazel/releases/download
	export USE_BAZEL_FALLBACK_VERSION=5.3.1
}

bazel_install() {
	go install github.com/bazelbuild/bazelisk@latest
	ln -sf "$(which bazelisk)" "$o_usr_env/bin/bazel"
}

docker_compose_install() {
	local os arch

	case "$(uname -m)" in
		x86_64) arch=x86_64 ;;
		arm64) arch=aarch64  ;;
		*) __errmsg "unsupported machine type: $(uname -m)" ;;
	esac
	case "$(uname -s)" in
		Darwin) os=darwin ;;
		Linux) os=linux  ;;
		*) __errmsg "unsupported system type: $(uname -s)" ;;
	esac

	local f="docker-compose-$os-$arch"
	local v="2.18.1"

	mget \
		--count 16 \
		--output docker-compose \
		--url "https://github.com/docker/compose/releases/download/v$v/$f"
	chmod a+x docker-compose
	mv docker-compose "$o_usr_env/bin/docker-compose"
	docker-compose version
}

terraform_install() {
	local ver="$1"
	local goos goarch
	local zipf
	local url

	if test -z "$ver"; then
		ver=1.9.8
		__errmsg "Defaulting to version $ver, see the doc for recent details"
		__errmsg ""
		__errmsg "  https://developer.hashicorp.com/terraform/install"
	fi
	goos="$(go_os)"
	goarch="$(go_arch)"
	zipf="terraform_${ver}_${goos}_${goarch}.zip"
	url="https://releases.hashicorp.com/terraform/${ver}/$zipf"

	local tmpd
	tmpd="$(mktemp -d terraform_install.XXX)"
	(
		cd "$tmpd"
		mget \
			--count 4 \
			--url "$url"
		unzip "$zipf"
		mv terraform "$o_usr_env/bin/terraform"
		terraform version
	)
	rm -rf "$tmpd"
}

docker_buildx_install() {
	local goos goarch
	local ver

	goos="$(go_os)"
	goarch="$(go_arch)"
	ver=0.13.1
	mget \
		--count 16 \
		--output docker-buildx \
		--url "https://github.com/docker/buildx/releases/download/v$ver/buildx-v$ver.$goos-$goarch"
	chmod a+x docker-buildx
	mkdir -p "$HOME/.docker/cli-plugins"
	mv docker-buildx "$HOME/.docker/cli-plugins/docker-buildx"
	docker buildx version
}

conda_install() {
	# anaconda vs. miniconda, anaconda is like dvd installer for linux
	# distro releases, while miniconda is like minimal installer.
	#
	# Install to $HOME/anaconda3 (prefix dir)
	#
	# Install & Uninstall,
	# https://conda.io/projects/conda/en/latest/user-guide/install/linux.html
	local conda_installer=Anaconda3-2023.07-2-Linux-x86_64.sh
	wget -c https://repo.anaconda.com/archive/$conda_installer
	chmod a+x $conda_installer
	./$conda_installer

	# With Intel® Extension for Scikit-learn* you can accelerate your
	# Scikit-learn applications and still have full conformance with all
	# Scikit-Learn APIs and algorithms. Intel® Extension for Scikit-learn*
	# is a free software AI accelerator that brings over 10-100X
	# acceleration across a variety of applications.
	#
	# https://intel.github.io/scikit-learn-intelex/
	conda install scikit-learn-intelex

	#conda init zsh
	#conda init --dry-run --verbose zsh
	#
	#conda config --set auto_activate_base false
}
