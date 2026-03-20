# Findings

## Scope
- 当前 `git diff --stat` 仅显示 9 个已修改文件：`Makefile.am`, `client.c`, `cmd.c`, `options-table.c`, `resize.c`, `screen-redraw.c`, `server-client.c`, `tmux.h`, `tty.c`。
- 核实后发现 `cmd-sidebar.c`, `sidebar.c`, `sidebar.h` 与 `regress/sidebar-*.sh` 存在于 worktree 中，但均为未跟踪文件；`git diff --stat` 未显示它们是因为尚未 `git add`。

## Review Focus
- session/global session 选项定义与默认值。
- client state、left redraw、输入白名单、鼠标单击/双击/滚轮路由。
- MVP 边界是否仍然保持 session 一层，且不侵入 tmux 原生操作流。

## Confirmed Issues
- Pane 区鼠标坐标在 sidebar 可见时没有减去左侧偏移。`server-client.c` 仍以原始 `x` 参与 pane 命中与坐标换算，而 `tty_window_offset1()` 已把 `offset` 加进 `ox`，两边组合后会把右侧 pane 内点击整体向右错算一个 sidebar 偏移量，破坏原生 pane 鼠标流。
- 小终端宽度边界处理不满足设计约束。`sidebar_client_width()` 仅在 `sx > pane_min + divider` 时才收缩 sidebar；当总宽度为 `21` 列时不会收缩，实测 attach 后窗口宽度变成 `1x10`，右侧 pane 几乎不可用。

## Test Gaps
- `regress/sidebar-input.sh` 仅覆盖键盘白名单与非白名单透传，没有任何鼠标事件回归。
- 当前脚本也没有覆盖 prefix 键先进入 `prefix` table 后，再由非白名单键继续走原生绑定的兼容场景。
