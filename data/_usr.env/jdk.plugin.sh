
jdk_install() {
	cat <<EOF
Install jre/jdk from package managers

	sudo apt-get install openjdk-8-jre
	sudo apt-get install openjdk-8-jdk
	sudo yum install -y java-1.8.0-openjdk
	sudo yum install -y java-1.8.0-openjdk-devel

Install from prebuilt binaries

	jdk11_src="openjdk-11.0.1_linux-x64_bin.tar.gz"
	jdk11_url="https://download.java.net/java/GA/jdk11/13/GPL/\$jdk11_src"
	mget --url "\$jdk_url" --count 8
	tar -C "$o_usr/jdk" -xzf "\$jdk11_url"

- How to download and install prebuilt OpenJDK packages, https://openjdk.java.net/install/
EOF
}

# java
_jdk_path_match() {
	local dir="$1"

	if [ "${dir#$o_usr/jdk/}" != "$dir" ]; then
		return 0
	else
		return 1
	fi
}

# list absolute pathes to jdk-x.x.x
jdk_list() {
	echo "$o_usr/jdk/jdk-"* \
			| tr ' ' '\n' \
			| sort --version-sort --reverse
}

# select and make permanent the selection
#
# The priority of version source to be consulted:
#
#  1. $1 arg
#  2. content of $o_usr/jdk/.jdkver
#  3. the most recent version of jdk_list
#
jdk_select() {
	local ver="$1"
	local q="$2"
	local jdkver="$o_usr/jdk/.jdkver"
	local jdkhome

	if [ ! -d "$o_usr/jdk" ]; then
		return 1
	fi
	[ -n "$ver" ] || ver="$(cat "$jdkver" 2>/dev/null)"
	if [ -z "$ver" ]; then
		jdkhome="$(jdk_list | head -n1)"
		ver="${jdkhome##*-}"
	else
		jdkhome="$o_usr/jdk/jdk-$ver"
	fi
	if [ ! -d "$jdkhome" ]; then
		if [ -z "$q" ]; then
			__errmsg "$jdkhome does not exist"
		fi
		return 1
	fi

	export JAVA_HOME="$jdkhome"
	# clear out other "$o_usr/jdk" subdirs in PATH
	path_ignore_match PATH _jdk_path_match
	path_action PATH prepend "$JAVA_HOME/bin"
	echo "$ver" >"$jdkver"
}
