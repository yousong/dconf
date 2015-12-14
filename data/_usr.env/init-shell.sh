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
	export LDFLAGS="$LDFLAGS -L$PREFIX_USR/lib"
}

[ -d "/sbin" ] && path_prepend PATH "/sbin" peek
[ -d "/usr/sbin" ] && path_prepend PATH "/usr/sbin" peek
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

# golang
[ -d "$HOME/go/bin" ] && {
	export GOROOT="$HOME/go"
	export GOPATH="$HOME/.gopath"
	path_prepend PATH "$GOROOT/bin"
	path_prepend PATH "$GOPATH/bin"
}

if [ -z "$MANPATH" ]; then
	MANPATH="$(manpath)"
fi
path_prepend MANPATH "$PREFIX_USR/share/man"
path_prepend PATH "$PREFIX_USR/sbin"
path_prepend PATH "$PREFIX_USR/bin"
case "$__os" in
	Darwin)
		path_prepend DYLD_LIBRARY_PATH "$PREFIX_USR/lib"
		;;
	Linux)
		path_prepend LD_LIBRARY_PATH "$PREFIX_USR/lib"
		;;
esac

# vim can be installed under $PREFIX_USR
if type vim 1>/dev/null 2>&1; then
	export EDITOR=vim
	alias vi=vim
else
	export EDITOR=vi
fi

# colorful ls output
_init_color() {
	local colors="$PREFIX_USR_ENV/dircolors-solarized/dircolors.ansi-dark"
	[ -r "$colors" ] || {
		__errmsg "$colors not found."
	}
	eval $(dircolors "$colors")
}
_init_color

# colorful man page
man() {
	env LESS_TERMCAP_mb=$'\E[01;31m' \
		LESS_TERMCAP_md=$'\E[01;38;5;74m' \
		LESS_TERMCAP_me=$'\E[0m' \
		LESS_TERMCAP_se=$'\E[0m' \
		LESS_TERMCAP_so=$'\E[38;5;246;44m' \
		LESS_TERMCAP_ue=$'\E[0m' \
		LESS_TERMCAP_us=$'\E[04;38;5;146m' \
		man "$@"
}

if [ -r "$PREFIX_USR_ENV/.env.sh" ]; then
	. "$PREFIX_USR_ENV/.env.sh"
fi
