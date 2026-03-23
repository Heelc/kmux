#!/bin/sh

PATH=/bin:/usr/bin
TERM=screen

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
[ -z "$TEST_TMUX" ] && TEST_TMUX=$SCRIPT_DIR/../tmux
TMUX="$TEST_TMUX -Ltest"
$TMUX kill-server >/dev/null 2>&1

TMP=$(mktemp)

cleanup() {
	$TMUX kill-server >/dev/null 2>&1
	rm -f "$TMP"
}
trap cleanup 0 1 15

$TMUX -f/dev/null new-session -d -s sidebar-a -x 80 -y 24 || exit 1
$TMUX -f/dev/null new-session -d -s sidebar-b -x 80 -y 24 || exit 1
$TMUX set -g status off || exit 1
$TMUX set -g sidebar on || exit 1
$TMUX bind-key -n x set-option -gq @sidebar_nonwhite hit || exit 1
$TMUX bind-key -n j set-option -gq @sidebar_white leaked || exit 1

(echo "refresh-client -C 80,24"; sleep 5) | \
	$TMUX -f/dev/null -C attach-session -t sidebar-a >"$TMP" 2>&1 &
sleep 0.5

CLIENT=$($TMUX list-clients -F '#{client_name}' 2>/dev/null | head -1)
[ -n "$CLIENT" ] || {
	cat "$TMP" >&2
	echo "no client attached" >&2
	exit 1
}

$TMUX focus-sidebar -c "$CLIENT" >/dev/null 2>&1 || {
	cat "$TMP" >&2
	exit 1
}
sleep 0.2

$TMUX send-keys -K -c "$CLIENT" -t sidebar-a:0 j >/dev/null 2>&1 || exit 1
sleep 0.2
LEAKED=$($TMUX show-options -gqv @sidebar_white 2>/dev/null)
[ -z "$LEAKED" ] || {
	echo "sidebar white-list key leaked: $LEAKED" >&2
	exit 1
}
ACTIVE=$($TMUX list-clients -F '#{client_name} #{session_name}' 2>/dev/null | \
		sed -n "s/^$CLIENT //p")
[ "$ACTIVE" = "sidebar-b" ] || {
	echo "sidebar j did not switch session: $ACTIVE" >&2
	exit 1
}

$TMUX send-keys -K -c "$CLIENT" -t sidebar-a:0 x >/dev/null 2>&1 || exit 1
sleep 0.2
HIT=$($TMUX show-options -gqv @sidebar_nonwhite 2>/dev/null)
[ "$HIT" = "hit" ] || {
	echo "non-sidebar key binding missed: $HIT" >&2
	exit 1
}

$TMUX send-keys -K -c "$CLIENT" -t sidebar-a:0 k >/dev/null 2>&1 || exit 1
sleep 0.2
ACTIVE=$($TMUX list-clients -F '#{client_name} #{session_name}' 2>/dev/null | \
		sed -n "s/^$CLIENT //p")
[ "$ACTIVE" = "sidebar-a" ] || {
	echo "sidebar k did not switch session: $ACTIVE" >&2
	exit 1
}

$TMUX set-option -gqu @sidebar_white >/dev/null 2>&1 || exit 1
$TMUX focus-sidebar -c "$CLIENT" >/dev/null 2>&1 || {
	cat "$TMP" >&2
	exit 1
}
sleep 0.2

$TMUX send-keys -K -c "$CLIENT" -t sidebar-a:0 j >/dev/null 2>&1 || exit 1
sleep 0.2
HIT=$($TMUX show-options -gqv @sidebar_white 2>/dev/null)
[ "$HIT" = "leaked" ] || {
	echo "focus-sidebar did not exit focus: $HIT" >&2
	exit 1
}
ACTIVE=$($TMUX list-clients -F '#{client_name} #{session_name}' 2>/dev/null | \
		sed -n "s/^$CLIENT //p")
[ "$ACTIVE" = "sidebar-a" ] || {
	echo "focus-sidebar toggle leaked sidebar focus: $ACTIVE" >&2
	exit 1
}

$TMUX detach-client -t "$CLIENT" >/dev/null 2>&1 || {
	cat "$TMP" >&2
	exit 1
}

exit 0
