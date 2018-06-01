tmux_do() {
	local insn

	while [ "$#" -gt 0 ]; do
		insn="$1"; shift
		case "$insn" in
			sh) tmux split-window -h ;;
			sv) tmux split-window ;;
			gl) tmux select-pane -L ;;
			gr) tmux select-pane -R ;;
			gu) tmux select-pane -U ;;
			gd) tmux select-pane -D ;;
			sp) tmux select-pane -t "$1"; shift 1 ;;
			sk) tmux send-keys -t "$1" "$2"; shift 2 ;;
			wt) sleep "$1"; shift 1;;
			*)
				__errmsg "unknown instruction $insn"
				;;
		esac
	done
}

tmux_alert() {
	while true; do
		tmux select-pane -m # mark it
		tmux display-message "#{window_index}:#{pane_index} alert: $@"
		sleep 5
		tmux select-pane -M # unmark to make the next mark work
	done
	# unmark it by <prefix>,m
}
