# kmux Sidebar Shortcut UX Design

## Context

native sidebar 已默认开启，但缺少贴近用户本机 tmux 生态的默认入口。用户本机最接近 session/workspace 的无前缀绑定是 `Option + s`，当前对应 `choose-tree -s`。

## Goals

- 给 sidebar 提供默认、低冲突的键盘入口
- 尽量复用用户现有的 session/workspace 肌肉记忆
- 保留原有 session chooser 能力

## Decisions

- `Option + s` 绑定到 `focus-sidebar`
- `focus-sidebar` 改为 toggle 语义：
  - 不在 sidebar 焦点时进入 sidebar 焦点
  - 已在 sidebar 焦点时退出到右侧 pane
- `Option + Shift + s` 绑定到原 session chooser：
  - `choose-tree -s`
- sidebar 默认常驻显示，`Option + s` 不承担显示/隐藏职责
- 进入 sidebar 焦点后：
  - `j/k/g/G` 继续“移动即切换”
  - 焦点保持在 sidebar
  - `Esc` 退出 sidebar 焦点

## Constraints

- 不覆盖用户已有 prefix、pane/window 导航习惯
- 不修改用户本机 `~/.tmux.conf.local`
- 默认绑定应落在 tmux 内建 key table，而不是额外配置文件

## Validation

- `list-keys` 可看到：
  - `bind-key -T root M-s focus-sidebar`
  - `bind-key -T root M-S choose-tree -s`
- `focus-sidebar` 连续执行两次时：
  - 第一次进入 sidebar 焦点
  - 第二次退出 sidebar 焦点
- 退出后 `j` 不再被 sidebar 截获，而是恢复 tmux 原有 root binding 路径
