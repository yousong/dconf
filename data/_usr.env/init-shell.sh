__os=$(uname -s)
if [ -n "$BASH_VERSION" ]; then
   	__sh="bash"
elif [ -n "$ZSH_VERSION" ]; then
	__sh="zsh"
fi
__errmsg() {
	echo "$1" >&2
}
PREFIX_USR="$HOME/.usr"
PREFIX_USR_ENV="$HOME/.usr.env"

export LC_ALL=en_GB.UTF-8
export LANG=en_GB.UTF-8

if type vim 1>/dev/null 2>&1; then
	export EDITOR=vim
	alias vi=vim
else
	export EDITOR=vi
fi
export CLICOLOR=1
export GREP_OPTIONS="--color=auto"

. $PREFIX_USR_ENV/misc.plugin.sh
. $PREFIX_USR_ENV/sshfs.plugin.sh
. $PREFIX_USR_ENV/openwrt.plugin.sh

setup_dev_env() {
	# MacPorts
	[ "$__os" = "Darwin" ] && {
		export CFLAGS="$CFLAGS -I/opt/local/include"
		export CPPFLAGS="$CPPFLAGS -I/opt/local/include"
		export LDFLAGS="$LDFLAGS -L/opt/local/lib"
	}
	# User prefix dir
	export CFLAGS="$CFLAGS -I$PREFIX_USR/include"
	export CPPFLAGS="$CPPFLAGS -I$PREFIX_USR/include"
	export LDFLAGS="$LDFLAGS -I$PREFIX_USR/lib"
}

# golang
[ -d "$HOME/go/bin" ] && {
	export GOROOT="$HOME/go"
	export GOPATH="$HOME/.gopath"
	path_prepend PATH "$GOROOT/bin"
	path_prepend PATH "$GOPATH/bin"
}

#powerline
POWERLINE_REPO_ROOT="$HOME/.vim/bundle/powerline"
[ -d "$POWERLINE_REPO_ROOT" ] && {
	export POWERLINE_REPO_ROOT
	export POWERLINE_ROOT="$POWERLINE_REPO_ROOT/powerline"
	#path_prepend PATH "/opt/local/Library/Frameworks/Python.framework/Versions/2.7/bin"
	path_prepend PATH "$POWERLINE_REPO_ROOT/scripts"
} || true

[ -d "/sbin" ] && path_prepend PATH "/sbin"
path_prepend PATH "$PREFIX_USR/bin"
path_prepend PATH "$PREFIX_USR/sbin"
path_prepend LD_LIBRARY_PATH "$PREFIX_USR/lib"

[ "$__os" = "Darwin" ] && {
	alias lockscreen='open /System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app'

	# MacPorts
	path_prepend PATH "/opt/local/bin"
	path_prepend PATH "/opt/local/sbin"
	path_prepend PATH "/opt/local/libexec/gnubin"

	# node
	[ -d "/opt/local/lib/node_modules" ] && \
		path_prepend NODE_PATH /opt/local/lib/node_modules || \
		true
}

_init_color() {
	local colors="$PREFIX_USR_ENV/dircolors-solarized/dircolors.ansi-dark"
	[ -r "$colors" ] || {
		__errmsg "$colors not found."
	}
	eval $(dircolors "$colors")
}
_init_color

if [ -r "$PREFIX_USR_ENV/.env.sh" ]; then
	. "$PREFIX_USR_ENV/.env.sh"
fi
