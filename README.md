My dotfiles for initializing configuration files for the following programs

- Git
- Tmux
- Screen
- Vim
- Shell
	- Common shell functions
	- Zsh and `.oh-my-zsh`
	- Bash

on following platforms

- Debian Wheezy
- Mac OS X with MacPorts
- CentOS 7

## How to use it.

Config a new system.

	./dconf.sh config
	o_homedir=$PWD/nh ./dconf.sh config

Collect current configuration

	./dconf.sh collect
	# git diff to find the change

Refresh patches

	# git format-patch --output-directory <patchdir> master..dconf
	./dconf.sh refresh_patches

## Files and directories

Git

- `$HOME/.gitconfig`

Tmux

- `$HOME/.tmux/`
- `$HOME/.tmux.conf`

Screen

- `$HOME/.screenrc`

Vim

- `$HOME/.vim/`
- `$HOME/.vimrc`

Shell

- `$HOME/.usr.env/`
- `$HOME/.oh-my-zsh/`
- `$HOME/.zshrc`
- `$HOME/.bashrc`

