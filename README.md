My dotfiles for initializing configuration files for the following programs

- Git
- Tmux
- Vim
- Shell
	- Common shell functions
	- Zsh and `.oh-my-zsh`
	- Bash

on following platforms

- Debian Wheezy
- Mac OS X with MacPorts

## How to use it.

Config a new system.

	./dconf.sh config

Collect current configuration

	./dconf.sh collect
	# git diff to find the change

## Files and directories

Git

- `$HOME/.gitconfig`

Tmux

- `$HOME/.tmux/`
- `$HOME/.tmux.conf`

Vim

- `$HOME/.vim/`
- `$HOME/.vimrc`

Shell

- `$HOME/.usr.env/`
- `$HOME/.oh-my-zsh/`
- `$HOME/.zshrc`
- `$HOME/.bashrc`

