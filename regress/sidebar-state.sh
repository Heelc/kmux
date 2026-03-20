#!/bin/sh

PATH=/bin:/usr/bin
TERM=screen

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
[ -z "$TEST_TMUX" ] && TEST_TMUX=$SCRIPT_DIR/../tmux
TMUX=$TEST_TMUX
"$TMUX" -Ltest kill-server >/dev/null 2>&1

TMP=$(mktemp)
OUT=$(mktemp)
trap '"$TMUX" -Ltest kill-server >/dev/null 2>&1; rm -f "$TMP" "$OUT"' 0 1 15

"$TMUX" -Ltest -f/dev/null new-session -d -s sidebar-main >/dev/null 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}

"$TMUX" -Ltest -f/dev/null show-options -g sidebar >$OUT 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
grep -qx "sidebar off" "$OUT" || {
	cat "$OUT" >&2
	exit 1
}

"$TMUX" -Ltest -f/dev/null show-options -g sidebar-width >$OUT 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
grep -qx "sidebar-width 24" "$OUT" || {
	cat "$OUT" >&2
	exit 1
}

"$TMUX" -Ltest -f/dev/null set-option -g sidebar on >/dev/null 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
"$TMUX" -Ltest -f/dev/null show-options -g sidebar >$OUT 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
grep -qx "sidebar on" "$OUT" || {
	cat "$OUT" >&2
	exit 1
}

"$TMUX" -Ltest -f/dev/null set-sidebar-default -g off >/dev/null 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
"$TMUX" -Ltest -f/dev/null show-options -g sidebar >$OUT 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
grep -qx "sidebar off" "$OUT" || {
	cat "$OUT" >&2
	exit 1
}

"$TMUX" -Ltest -f/dev/null set-sidebar-default -t sidebar-main on >/dev/null 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
"$TMUX" -Ltest -f/dev/null show-options -t sidebar-main sidebar >$OUT 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
grep -qx "sidebar on" "$OUT" || {
	cat "$OUT" >&2
	exit 1
}

"$TMUX" -Ltest -f/dev/null list-commands >$OUT 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
grep -q "^focus-sidebar " "$OUT" || {
	cat "$OUT" >&2
	exit 1
}
grep -q "^toggle-sidebar " "$OUT" || {
	cat "$OUT" >&2
	exit 1
}
grep -q "^set-sidebar-default " "$OUT" || {
	cat "$OUT" >&2
	exit 1
}
