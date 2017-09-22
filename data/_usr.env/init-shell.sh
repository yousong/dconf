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

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

. $PREFIX_USR_ENV/go.plugin.sh
. $PREFIX_USR_ENV/misc.plugin.sh
. $PREFIX_USR_ENV/openssl.plugin.sh
. $PREFIX_USR_ENV/openwrt.plugin.sh
. $PREFIX_USR_ENV/rust.plugin.sh
. $PREFIX_USR_ENV/sshfs.plugin.sh
. $PREFIX_USR_ENV/tmux.plugin.sh

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

[ -d "$PREFIX_USR_ENV/bin" ] && path_action PATH peek_prepend "$PREFIX_USR_ENV/bin"
[ -d "/sbin" ] && path_action PATH peek_append "/sbin"
[ -d "/usr/sbin" ] && path_action PATH peek_append "/usr/sbin"
[ "$__os" = "Darwin" ] && {
	alias lockscreen='open /System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app'

	# MacPorts
	path_action PATH prepend "/opt/local/bin"
	path_action PATH prepend "/opt/local/sbin"
	path_action PATH prepend "/opt/local/libexec/gnubin"

	# NodeJS
	if [ -d "/opt/local/lib/node_modules" ]; then
		path_action NODE_PATH prepend /opt/local/lib/node_modules
	fi
}
go_select "" quiet
rust_select "" quiet

if [ -z "$MANPATH" ]; then
	MANPATH="$(manpath)"
fi
path_action MANPATH prepend "$PREFIX_USR/share/man"
path_action PATH prepend "$PREFIX_USR/sbin"
path_action PATH prepend "$PREFIX_USR/bin"

export CLICOLOR=1
export GREP_OPTIONS="--color=auto"

# colorful ls output
_init_color() {
	local colors="$PREFIX_USR_ENV/dircolors-solarized/dircolors.ansi-dark"
	[ -r "$colors" ] || {
		__errmsg "$colors not found."
	}
	eval $(dircolors "$colors")
}
_init_color

# vim can be installed under $PREFIX_USR
if type vim 1>/dev/null 2>&1; then
	export EDITOR=vim
	alias vi=vim
else
	export EDITOR=vi
fi
vim_basic() {
	vim -u "$HOME/.vimrc.basic" "$@"
}

# Use GNU ls
alias ls="ls --color=auto --group-directories-first"

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
