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

# How to use it.

Config a new system.

	./dconf.sh config
	o_homedir=$PWD/nh ./dconf.sh config

Collect current configuration

	./dconf.sh collect
	# git diff to find the change

Refresh patches

	# git format-patch --output-directory <patchdir> master..dconf
	./dconf.sh refresh_patches

## Use it inside docker container

	docker run \
		--name dev \
		--interactive \
		--tty \
		--privileged \
		--pid=host \
		--network=host \
		--env id_id="$(id)" \
		--volume /var/run:/var/run \
		--volume $HOME/git-repo:/home/abc/git-repo \
		--volume $HOME/go/src:/home/abc/go/src \
		yousong/dconf

The container entrypoint will switch to user `abc` and start there.

The behaviour can be customized in following ways by passing it an environment variable `id_id` with value in the form of command `id` output.  The entrypoint will then try to form a user/group environment resemling of that setting.  This can be useful for consistent file ownerships across container boundaries and it's also convenient for things like accessing docker engine socket

Things to watch out for
 - Configs were pre-configured for user "abc" inside the container.  Setting /home/abc as destination of a volume will make those configs unavailable

# Files and directories

- `$HOME/.gitconfig`
- `$HOME/.tmux/`
- `$HOME/.tmux.conf`
- `$HOME/.screenrc`
- `$HOME/.vim/`
- `$HOME/.vimrc`
- `$HOME/.usr.env/`
- `$HOME/.oh-my-zsh/`
- `$HOME/.zshrc`
- `$HOME/.bashrc`
- ...
