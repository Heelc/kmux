#!/bin/sh

PATH=/bin:/usr/bin
TERM=screen

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
[ -z "$TEST_TMUX" ] && TEST_TMUX=$SCRIPT_DIR/../tmux
TMUX=$TEST_TMUX

TMP=$(mktemp)
trap '"$TMUX" -Ltest kill-server >/dev/null 2>&1; rm -f "$TMP"' 0 1 15

PAYLOAD=12345678901234567890123456789012345678901234567890123456789012345678901234567890

"$TMUX" -Ltest kill-server >/dev/null 2>&1
"$TMUX" -Ltest -f/dev/null new-session -d -s alpha -x 80 -y 24 \
	'sleep 1000' || exit 1
"$TMUX" -Ltest -f/dev/null new-session -d -s beta -x 80 -y 24 \
	"sh -lc 'printf \"%s\\n\" \"$PAYLOAD\"; sleep 1000'" || exit 1
"$TMUX" -Ltest -f/dev/null set -g status off || exit 1
"$TMUX" -Ltest -f/dev/null set -g sidebar on || exit 1

(echo "refresh-client -C 80,24"; sleep 2) | \
	"$TMUX" -Ltest -f/dev/null -C attach -t alpha >"$TMP" 2>&1 &
CONTROL_PID=$!
sleep 0.2

CLIENT=$("$TMUX" -Ltest -f/dev/null list-clients -F '#{client_name}' \
	2>/dev/null | head -1)
[ -n "$CLIENT" ] || {
	cat "$TMP" >&2
	echo "no client attached" >&2
	exit 1
}

"$TMUX" -Ltest -f/dev/null focus-sidebar -c "$CLIENT" >/dev/null 2>&1 || {
	cat "$TMP" >&2
	exit 1
}
sleep 0.2

"$TMUX" -Ltest -f/dev/null send-keys -K -c "$CLIENT" -t alpha:0 j \
	>/dev/null 2>&1 || exit 1
sleep 0.2
"$TMUX" -Ltest -f/dev/null send-keys -K -c "$CLIENT" -t alpha:0 Enter \
	>/dev/null 2>&1 || exit 1
sleep 0.2

LINE1=$("$TMUX" -Ltest -f/dev/null capture-pane -pt beta:0.0 -S -10 -E 1 | \
	sed -n '1p')
LINE2=$("$TMUX" -Ltest -f/dev/null capture-pane -pt beta:0.0 -S -10 -E 1 | \
	sed -n '2p')

kill "$CONTROL_PID" >/dev/null 2>&1 || true

case "$LINE1" in
"1234567890123456789012345678901234567890123456789012345") ;;
*)
	echo "unexpected first line after sidebar switch: $LINE1" >&2
	exit 1
	;;
esac

[ -z "$LINE2" ] || {
	echo "sidebar switch reflow leaked onto second line: $LINE2" >&2
	exit 1
}

exit 0
