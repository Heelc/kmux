#!/bin/sh

PATH=/bin:/usr/bin
TERM=screen

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
[ -z "$TEST_TMUX" ] && TEST_TMUX=$SCRIPT_DIR/../tmux
TMUX=$TEST_TMUX
EXPECT_BIN=/usr/bin/expect

[ -x "$EXPECT_BIN" ] || {
	echo "expect not found: $EXPECT_BIN" >&2
	exit 1
}

"$TMUX" -Ltest kill-server >/dev/null 2>&1

BASE=$(mktemp /tmp/kmux-sidebar-mouse.XXXXXX) || exit 1
EXPECT_SCRIPT="$BASE.exp"

cleanup() {
	"$TMUX" -Ltest kill-server >/dev/null 2>&1
	rm -f "$BASE" "$EXPECT_SCRIPT"
}
trap cleanup 0 1 15

cat >"$EXPECT_SCRIPT" <<'EOF'
#!/usr/bin/expect -f
set timeout 5
set tmux $env(TMUX_BIN)
spawn sh -lc "TERM=xterm-256color; export TERM; stty rows 24 cols 80; exec \"$tmux\" -Ltest -f/dev/null attach -t mouse-test"
after 1500
send -- "\033\[<0;27;3M"
after 100
send -- "\033\[<0;27;3m"
after 400
send -- "\002d"
expect eof
EOF

"$TMUX" -Ltest -f/dev/null new-session -d -s mouse-test -x 80 -y 24 \
	'sleep 1000' || exit 1
"$TMUX" -Ltest -f/dev/null split-window -h -t mouse-test:0 \
	'sleep 1000' || exit 1
"$TMUX" -Ltest -f/dev/null set -g status off || exit 1
"$TMUX" -Ltest -f/dev/null set -g mouse on || exit 1
"$TMUX" -Ltest -f/dev/null set -g sidebar on || exit 1
"$TMUX" -Ltest -f/dev/null select-pane -t mouse-test:0.1 || exit 1

LEFT=$("$TMUX" -Ltest -f/dev/null list-panes -t mouse-test:0 \
	-F '#{pane_left} #{pane_id}' 2>/dev/null | sort -n | \
	awk 'NR == 1 { print $2 }')
[ -n "$LEFT" ] || {
	echo "missing left pane id" >&2
	exit 1
}

TMUX_BIN=$TMUX "$EXPECT_BIN" "$EXPECT_SCRIPT" >/dev/null 2>&1 || true

sleep 0.2

ACTIVE=$("$TMUX" -Ltest -f/dev/null list-panes -t mouse-test:0 \
	-F '#{pane_active} #{pane_id}' 2>/dev/null | \
	awk '$1 == 1 { print $2 }')
[ "$ACTIVE" = "$LEFT" ] || {
	echo "sidebar pane mouse routing failed: $ACTIVE != $LEFT" >&2
	exit 1
}

exit 0
