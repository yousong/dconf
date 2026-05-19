My dotfiles for initializing configuration files for the following programs

- Git
- Tmux
- Screen
- Vim
- Shell
	- Common shell functions
	- Zsh and `.oh-my-zsh`
	- Bash
- Docker
- Cargo/Rust
- Conda
- Pip/Python
- npm/Node.js
- Maven
- Mercurial (hg)
- GDB
- Ctags
- FZF
- Rime (Wubi86)
- Terraform
- pwclient
- Claude
- OpenCode
- mise
- uv
- ccache
- Brew (macOS)
- Maccy (macOS)
- Notes (macOS)

on following platforms

- Debian
- Mac OS X with MacPorts/Homebrew
- CentOS

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

## Managed config paths

The following paths are managed by this repository:

- `$HOME/.bashrc`
- `$HOME/.zshrc`
- `$HOME/.gitconfig`
- `$HOME/.tmux.conf`
- `$HOME/.screenrc`
- `$HOME/.vimrc`
- `$HOME/.gdbinit`
- `$HOME/.hgrc`
- `$HOME/.ctags`
- `$HOME/.condarc`
- `$HOME/.npmrc`
- `$HOME/.pwclientrc`
- `$HOME/.terraformrc`
- `$HOME/.claude_settings.json`
- `$HOME/.config/opencode/opencode.jsonc`
- `$HOME/.mise_config.toml`
- `$HOME/.config/uv/uv.toml`
- `$HOME/.Brewfile`
- `$HOME/.cargo/config`
- `$HOME/.docker/config.json`
- `$HOME/.m2/settings.xml`
- `$HOME/.pip/pip.conf`
- `$HOME/.usr.env/`
- `$HOME/.ccache`
- Rime input method configs
- MacPorts configuration files
