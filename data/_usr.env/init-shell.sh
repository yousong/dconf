__os=$(uname -s)
if [ -n "$BASH_VERSION" ]; then
   	__sh="bash"
elif [ -n "$ZSH_VERSION" ]; then
	__sh="zsh"
fi
__errmsg() {
	echo "$1" >&2
}
o_usr="$HOME/.usr"
o_usr_env="$HOME/.usr.env"

export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8

# required by hub from github, https://github.com/github/hub
# it stores credentials at $HOME/.config/hub
export GITHUB_USER=yousong

. $o_usr_env/distver.plugin.sh
. $o_usr_env/misc.plugin.sh
. $o_usr_env/openssl.plugin.sh
. $o_usr_env/openwrt.plugin.sh
. $o_usr_env/sshfs.plugin.sh
. $o_usr_env/tmux.plugin.sh

if [ "$__os" = "Darwin" ]; then
	if [ -x "/usr/local/bin/brew" ]; then
		o_osx_who=brew
		o_osx_where="/usr/local"
	elif [ -x "/opt/local/bin/port" ]; then
		o_osx_who=port
		o_osx_where="/opt/local"
	else
		__errmsg "no package manager detected"
		false
	fi
fi

setup_dev_env() {
	# MacPorts
	[ "$__os" = "Darwin" ] && {
		export CFLAGS="$CFLAGS -I$o_osx_where/include"
		export CPPFLAGS="$CPPFLAGS -I$o_osx_where/include"
		export LDFLAGS="$LDFLAGS -L$o_osx_where/lib"
	}
	# User prefix dir
	export CFLAGS="$CFLAGS -I$o_usr/include"
	export CPPFLAGS="$CPPFLAGS -I$o_usr/include"
	export LDFLAGS="$LDFLAGS -L$o_usr/lib"
}

[ -d "$o_usr_env/bin" ] && path_action PATH peek_prepend "$o_usr_env/bin"
[ -d "/sbin" ] && path_action PATH peek_append "/sbin"
[ -d "/usr/sbin" ] && path_action PATH peek_append "/usr/sbin"
if [ -z "$MANPATH" ]; then
	MANPATH="$(manpath)"
fi
[ "$__os" = "Darwin" ] && {
	alias lockscreen='open /System/Library/Frameworks/ScreenSaver.framework/Versions/A/Resources/ScreenSaverEngine.app'

	# MacPorts
	path_action PATH prepend "$o_osx_where/bin"
	path_action PATH prepend "$o_osx_where/sbin"
	case "$o_osx_who" in
		port)
			path_action PATH prepend "$o_osx_where/libexec/gnubin"
			;;
		brew)
			path_action PATH prepend "$o_osx_where/opt/coreutils/libexec/gnubin"
			path_action MANPATH prepend "$o_osx_where/opt/coreutils/libexec/gnuman"
			export HOMEBREW_BOTTLE_DOMAIN=https://mirrors.ustc.edu.cn/homebrew-bottles
			;;
	esac

	# NodeJS
	if [ -d "$o_osx_where/lib/node_modules" ]; then
		path_action NODE_PATH prepend $o_osx_where/lib/node_modules
	fi
}
go_select "" quiet
rust_env_init

path_action MANPATH prepend "$o_usr/share/man"
path_action PATH prepend "$o_usr/sbin"
path_action PATH prepend "$o_usr/bin"

export CLICOLOR=1
export GREP_OPTIONS="--color=auto"

# colorful ls output
_init_color() {
	local colors="$o_usr_env/dircolors-solarized/dircolors.ansi-dark"
	[ -r "$colors" ] || {
		__errmsg "$colors not found."
	}
	eval $(dircolors "$colors")
}
_init_color

# vim can be installed under $o_usr
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

if [ -r "$o_usr_env/.env.sh" ]; then
	. "$o_usr_env/.env.sh"
fi
