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

go_get() {
	local group="$1"

	case "$group" in
		grpc)
			go get -u google.golang.org/grpc
			go get -u github.com/golang/protobuf/protoc-gen-go
			;;
		gops)
			go get -u github.com/google/gops
			;;
		*)
			go get "$@"
			;;
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
}

jdk_select_() {
	local distverroot="$1"; shift

	export JAVA_HOME="$distverroot"
	path_ignore_match PATH distver_path_match_ jdk
	path_action PATH prepend "$JAVA_HOME/bin"
}

jdk_select() {
	[ "$#" -gt 1 ] || set -- "$@" "" ""
	local ver="$1"; shift
	local q="$1"; shift

	distver_select_ jdk "$ver" "$q" jdk_select_
}

jdk_install() {
	cat <<EOF
Install jre/jdk from package managers

	sudo apt-get install openjdk-8-jre
	sudo apt-get install openjdk-8-jdk
	sudo yum install -y java-1.8.0-openjdk
	sudo yum install -y java-1.8.0-openjdk-devel

Install from prebuilt binaries

	jdk_src="openjdk-11.0.1_linux-x64_bin.tar.gz"
	jdk_url="https://download.java.net/java/GA/jdk11/13/GPL/\$jdk_src"
	mget --url "\$jdk_url" --count 8
	tar -C "$o_usr/jdk" -xzf "\$jdk_src"

- How to download and install prebuilt OpenJDK packages, https://openjdk.java.net/install/
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

k8s_install() {
	cat <<"EOF"
[ "$(uname -m)" = "x86_64" ]
[ "$(uname -s)" = "Linux" ]

kubebin="$HOME/.kube/bin"
mkdir -p "$kubebin"

# Installing helm, https://helm.sh/docs/intro/install/
u="https://get.helm.sh/helm-v3.7.0-linux-amd64.tar.gz"
u="https://mirrors.huaweicloud.com/helm/v3.7.0/helm-v3.7.0-linux-amd64.tar.gz"
( helmd="$(mktemp -d helm.XXX)"
  cd "$helmd"
  wget -c -O "helm.tar.gz" "$u"
  tar xzf helm.tar.gz
  find . -name helm | xargs -I{} mv {} "$kubebin"
  cd ..; rm -rvf "$helmd"
)

u="https://mirrors.aliyun.com/kubernetes/apt/pool/kubectl_1.22.2-00_amd64_9ef92050f0f5924a89dbdd8a62ea447828b1163f2d99b37f1f4b5435092959af.deb"
( kubectld="$(mktemp -d k.XXX)"
  cd "$kubectld"
  wget -c -O kubectl.deb "$u"
  ar x kubectl.deb data.tar.xz
  tar xJf data.tar.xz
  find . -name kubectl | xargs -I{} mv {} "$kubebin"
  cd ..; rm -rvf "$kubectld"
)

# Kustomize, https://kubectl.docs.kubernetes.io/installation/kustomize/binaries/
u="https://github.com/kubernetes-sigs/kustomize/releases/download/kustomize%2Fv4.3.0/kustomize_v4.3.0_linux_amd64.tar.gz"
( kustomized="$(mktemp -d kustomize.XXX)"
  cd "$kustomized"
  wget -c -O "kustomize.tar.gz" "$u"
  tar xzf kustomize.tar.gz
  find . -name kustomize | xargs -I{} mv {} "$kubebin"
  cd ..; rm -rvf "$kustomized"
)

regns=registry.aliyuncs.com/google_containers/kube-apiserver
EOF
}

k8s_init() {
	local d="$HOME/.kube/bin"

	if [ -d "$d" ]; then
		path_action PATH prepend "$d"
	fi
}
