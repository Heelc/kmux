#!/bin/sh

PATH=/bin:/usr/bin
TERM=screen

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
[ -z "$TEST_TMUX" ] && TEST_TMUX=$SCRIPT_DIR/../tmux
TMUX=$TEST_TMUX

TMP1=$(mktemp)
TMP2=$(mktemp)
TMP3=$(mktemp)
trap '"$TMUX" -Ltest-1 kill-server >/dev/null 2>&1; \
"$TMUX" -Ltest-2 kill-server >/dev/null 2>&1; \
"$TMUX" -Ltest-3 kill-server >/dev/null 2>&1; \
rm -f "$TMP1" "$TMP2" "$TMP3"' 0 1 15

"$TMUX" -Ltest-1 kill-server >/dev/null 2>&1
"$TMUX" -Ltest-1 -f/dev/null new-session -d -s sidebar-test -x 80 -y 24 \
	'sleep 1000' || exit 1
"$TMUX" -Ltest-1 -f/dev/null set -g status off || exit 1
"$TMUX" -Ltest-1 -f/dev/null set -g sidebar on || exit 1
(echo "refresh-client -C 80,24"; sleep 2) | \
	"$TMUX" -Ltest-1 -f/dev/null -C attach -t sidebar-test >$TMP1 2>&1 &
sleep 0.2
OUT1=$("$TMUX" -Ltest-1 -f/dev/null display -t sidebar-test:0 -p '#{window_width}x#{window_height}' \
	2>/dev/null)
[ "$OUT1" = "55x24" ] || {
	echo "sidebar default width failed: $OUT1" >&2
	exit 1
}

"$TMUX" -Ltest-2 kill-server >/dev/null 2>&1

"$TMUX" -Ltest-2 -f/dev/null new-session -d -s sidebar-test -x 42 -y 10 \
	'sleep 1000' || exit 1
"$TMUX" -Ltest-2 -f/dev/null set -g status off || exit 1
"$TMUX" -Ltest-2 -f/dev/null set -g sidebar on || exit 1
(echo "refresh-client -C 42,10"; sleep 2) | \
	"$TMUX" -Ltest-2 -f/dev/null -C attach -t sidebar-test >$TMP2 2>&1 &
sleep 0.2
OUT2=$("$TMUX" -Ltest-2 -f/dev/null display -t sidebar-test:0 -p '#{window_width}x#{window_height}' \
	2>/dev/null)
[ "$OUT2" = "20x10" ] || {
	echo "sidebar clamp failed: $OUT2" >&2
	exit 1
}

"$TMUX" -Ltest-3 kill-server >/dev/null 2>&1

"$TMUX" -Ltest-3 -f/dev/null new-session -d -s sidebar-test -x 21 -y 10 \
	'sleep 1000' || exit 1
"$TMUX" -Ltest-3 -f/dev/null set -g status off || exit 1
"$TMUX" -Ltest-3 -f/dev/null set -g sidebar on || exit 1
(echo "refresh-client -C 21,10"; sleep 2) | \
	"$TMUX" -Ltest-3 -f/dev/null -C attach -t sidebar-test >$TMP3 2>&1 &
sleep 0.2
OUT3=$("$TMUX" -Ltest-3 -f/dev/null display -t sidebar-test:0 -p '#{window_width}x#{window_height}' \
	2>/dev/null)
[ "$OUT3" = "21x10" ] || {
	echo "sidebar tiny clamp failed: $OUT3" >&2
	exit 1
}

exit 0
