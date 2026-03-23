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

BASE=$(mktemp /tmp/kmux-sidebar-click.XXXXXX) || exit 1
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
spawn sh -lc "TERM=xterm-256color; export TERM; stty rows 24 cols 80; exec \"$tmux\" -Ltest -f/dev/null attach -t sidebar-a"
after 1500
send -- "\033\[<0;3;2M"
after 100
send -- "\033\[<0;3;2m"
after 5000
EOF

"$TMUX" -Ltest -f/dev/null new-session -d -s sidebar-a -x 80 -y 24 \
	'sleep 1000' || exit 1
"$TMUX" -Ltest -f/dev/null new-session -d -s sidebar-b -x 80 -y 24 \
	"sh -lc 'while IFS= read line; do printf \"[%s]\\n\" \"\$line\"; done'" || exit 1
"$TMUX" -Ltest -f/dev/null set -g status off || exit 1
"$TMUX" -Ltest -f/dev/null set -g mouse on || exit 1
"$TMUX" -Ltest -f/dev/null set -g sidebar on || exit 1

TMUX_BIN=$TMUX "$EXPECT_BIN" "$EXPECT_SCRIPT" >/dev/null 2>&1 &
EXPECT_PID=$!

sleep 2

CLIENT=$("$TMUX" -Ltest -f/dev/null list-clients -F '#{client_name}' 2>/dev/null | head -1)
[ -n "$CLIENT" ] || {
	kill "$EXPECT_PID" >/dev/null 2>&1 || true
	echo "missing client after click attach" >&2
	exit 1
}

ACTIVE=$("$TMUX" -Ltest -f/dev/null list-clients -F '#{session_name}' 2>/dev/null | head -1)
[ "$ACTIVE" = "sidebar-b" ] || {
	kill "$EXPECT_PID" >/dev/null 2>&1 || true
	echo "sidebar single click failed: $ACTIVE" >&2
	exit 1
}

"$TMUX" -Ltest -f/dev/null send-keys -K -c "$CLIENT" -t sidebar-b:0 Enter || exit 1
sleep 0.2

CAPTURE=$("$TMUX" -Ltest -f/dev/null capture-pane -pt sidebar-b:0.0 2>/dev/null)
printf '%s\n' "$CAPTURE" | grep -q '^\[\]$' || {
	kill "$EXPECT_PID" >/dev/null 2>&1 || true
	echo "sidebar click did not return focus to pane" >&2
	exit 1
}

"$TMUX" -Ltest -f/dev/null detach-client >/dev/null 2>&1 || true
wait "$EXPECT_PID" >/dev/null 2>&1 || true

exit 0
