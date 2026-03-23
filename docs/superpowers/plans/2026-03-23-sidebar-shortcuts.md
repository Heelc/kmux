# Sidebar Shortcut UX Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 给 native sidebar 增加符合用户本机 tmux 生态的默认快捷键入口，并保留原 session chooser。

**Architecture:** 在 tmux 内建 root key table 中增加 `M-s`/`M-S` 默认绑定；同时把 `focus-sidebar` 调整为可进入也可退出的 toggle 语义。现有 sidebar 输入白名单和鼠标路径保持不变。

**Tech Stack:** C, tmux key tables, shell regress

---

## Chunk 1: 回归先行

### Task 1: 默认绑定回归

**Files:**
- Modify: `/Users/KaiHe/workspace/ai_prj/kmux/.worktrees/sidebar-mvp-impl/regress/sidebar-state.sh`

- [ ] **Step 1: 写默认绑定红测**

断言 `list-keys` 中存在：

```sh
bind-key    -T root         M-s                       focus-sidebar
bind-key    -T root         M-S                       choose-tree -s
```

- [ ] **Step 2: 运行红测**

Run: `sh regress/sidebar-state.sh`
Expected: FAIL，因为当前还没有默认 `M-s/M-S` 绑定。

### Task 2: focus-sidebar toggle 红测

**Files:**
- Modify: `/Users/KaiHe/workspace/ai_prj/kmux/.worktrees/sidebar-mvp-impl/regress/sidebar-input.sh`

- [ ] **Step 1: 写 toggle 语义红测**

在已有 `focus-sidebar -> j -> switch` 之后，再执行一次 `focus-sidebar`，然后发送 `j`，断言：

- `j` 不再切换 session
- `j` 回到 root binding 路径

- [ ] **Step 2: 运行红测**

Run: `sh regress/sidebar-input.sh`
Expected: FAIL，因为当前 `focus-sidebar` 只能进入，不能退出。

## Chunk 2: 最小实现

### Task 3: focus-sidebar toggle 语义

**Files:**
- Modify: `/Users/KaiHe/workspace/ai_prj/kmux/.worktrees/sidebar-mvp-impl/cmd-sidebar.c`

- [ ] **Step 1: 最小实现**

当 target client 已在 sidebar focus 且 sidebar 可见时，`focus-sidebar` 改为执行 `sidebar_unfocus_client()`；否则维持原进入焦点行为。

- [ ] **Step 2: 运行输入回归**

Run: `sh regress/sidebar-input.sh`
Expected: PASS

### Task 4: 默认 root 绑定

**Files:**
- Modify: `/Users/KaiHe/workspace/ai_prj/kmux/.worktrees/sidebar-mvp-impl/key-bindings.c`

- [ ] **Step 1: 最小实现**

在默认 key table 中增加：

```c
"bind -N 'Focus the sidebar workspace list' -n M-s { focus-sidebar }",
"bind -N 'Choose a session from a list' -n M-S { choose-tree -s }",
```

- [ ] **Step 2: 运行状态回归**

Run: `sh regress/sidebar-state.sh`
Expected: PASS

## Chunk 3: 收尾验证

### Task 5: 串行回归

**Files:**
- Test: `/Users/KaiHe/workspace/ai_prj/kmux/.worktrees/sidebar-mvp-impl/regress/sidebar-state.sh`
- Test: `/Users/KaiHe/workspace/ai_prj/kmux/.worktrees/sidebar-mvp-impl/regress/sidebar-input.sh`
- Test: `/Users/KaiHe/workspace/ai_prj/kmux/.worktrees/sidebar-mvp-impl/regress/sidebar-click-switch.sh`

- [ ] **Step 1: 运行关键 sidebar 回归**

Run:

```bash
sh regress/sidebar-state.sh
sh regress/sidebar-input.sh
sh regress/sidebar-click-switch.sh
```

Expected: PASS
