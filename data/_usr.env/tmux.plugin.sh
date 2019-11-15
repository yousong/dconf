#
# An example
#
#	tmux_do \
#		sv \
#		sh \
#		gu \
#		sh \
#		sk 0 "ssh root@1.2.3.4" \
#		sk 1 "ssh root@1.2.3.4" \
#		sk 2 "ssh root@1.2.3.4" \
#		sk 3 "ssh root@1.2.3.4" \
#		sk 0 Enter \
#		sk 1 Enter \
#		sk 2 Enter \
#		sk 3 Enter \
#		wt 2 \
#		sk 0 "password" \
#		sk 1 "password" \
#		sk 2 "password" \
#		sk 3 "password" \
#		sk 0 Enter \
#		sk 1 Enter \
#		sk 2 Enter \
#		sk 3 Enter \
#		&
#
# See "KEY BINDINGS" to find key spec details
#
#	C-a	Ctrl-a
#	Enter
#	Up, Down, Left, Right
#	BSpace
#
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

tmux_show_pane_status() {
	local cmd0
	local cmd1

	cmd0='ps --no-headers -o tpgid   -p "#{pane_pid}" | grep -oE "[0-9]+"'
	cmd1='ps --no-headers -o command -p "$('"$cmd0"')"'
	tmux set-window-option -t : pane-border-status top
	tmux set-window-option -t : pane-border-format "#{pane_index} #($cmd1)"
}
