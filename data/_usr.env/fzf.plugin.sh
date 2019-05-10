o_fzf="$HOME/.fzf"
if [ -d "$o_fzf" ]; then
	source "$o_fzf/shell/completion.$__sh"
	source "$o_fzf/shell/key-bindings.$__sh"

	export FZF_CTRL_T_OPTS="--select-1 --exit-0 --preview 'less {}'"
fi
