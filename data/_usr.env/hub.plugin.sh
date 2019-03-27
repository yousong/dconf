# required by hub from github, https://github.com/github/hub
# it stores credentials at $HOME/.config/hub
export GITHUB_USER=yousong

hub() {
	local arg
	local -a extra_args
	local can_list

	for arg in "$@"; do
		case "$arg" in
			pr|issue)
				can_list=1
				;;
			list)
				if [ -n "$can_list" ]; then
					# insert author name between indx and title
					extra_args+=(--format='%sC%>(8)%i%Creset  %<(12,trunc)%au  %t%  l%n')
				fi
				;;
		esac
	done

	command hub "$@" "${extra_args[@]}"
}
