#!/bin/sh

PATH=/bin:/usr/bin
TERM=screen

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
[ -z "$TEST_TMUX" ] && TEST_TMUX=$SCRIPT_DIR/../tmux
TMUX=$TEST_TMUX
"$TMUX" -Ltest kill-server >/dev/null 2>&1

TMP=$(mktemp)
OUT=$(mktemp)
EXAMPLE_CONF=$(cd "$SCRIPT_DIR/.." && pwd)/example_tmux.conf
trap '"$TMUX" -Ltest kill-server >/dev/null 2>&1; "$TMUX" -Ltest-example kill-server >/dev/null 2>&1; rm -f "$TMP" "$OUT"' 0 1 15

"$TMUX" -Ltest -f/dev/null new-session -d -s sidebar-main >/dev/null 2>$TMP || {
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

"$TMUX" -Ltest -f/dev/null show-options -g mouse >$OUT 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
grep -qx "mouse on" "$OUT" || {
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

"$TMUX" -Ltest -f/dev/null list-keys >$OUT 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
grep -q "bind-key    -T root         M-s                       focus-sidebar" "$OUT" || {
	cat "$OUT" >&2
	exit 1
}
grep -q "bind-key    -T root         M-S                       choose-tree -s" "$OUT" || {
	cat "$OUT" >&2
	exit 1
}

"$TMUX" -Ltest-example kill-server >/dev/null 2>&1
"$TMUX" -Ltest-example -f/dev/null new-session -d -s sidebar-example >/dev/null 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
"$TMUX" -Ltest-example -f/dev/null set-option -g sidebar off >/dev/null 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
"$TMUX" -Ltest-example -f/dev/null source-file "$EXAMPLE_CONF" >/dev/null 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
"$TMUX" -Ltest-example -f/dev/null show-options -g sidebar >$OUT 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
grep -qx "sidebar on" "$OUT" || {
	cat "$OUT" >&2
	exit 1
}
"$TMUX" -Ltest-example -f/dev/null list-keys >$OUT 2>$TMP || {
	cat "$TMP" >&2
	exit 1
}
grep -q "bind-key    -T root         M-r                       command-prompt -I \"#S\" \"rename-session '%%'\"" "$OUT" || {
	cat "$OUT" >&2
	exit 1
}
grep -q "bind-key    -T root         M-D                       split-window -v -c \"#{pane_current_path}\"" "$OUT" || {
	cat "$OUT" >&2
	exit 1
}
grep -q "bind-key    -T root         M-s                       focus-sidebar" "$OUT" || {
	cat "$OUT" >&2
	exit 1
}
grep -q "bind-key    -T root         M-S                       choose-tree -s" "$OUT" || {
	cat "$OUT" >&2
	exit 1
}
