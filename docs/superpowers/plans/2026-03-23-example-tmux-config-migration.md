# Example tmux Config Migration Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 把用户本机 tmux 配置中最稳定的基础主题和高频 `Option` 快捷键迁移为 `kmux` 项目内可分发的分层示例配置。

**Architecture:** 保留一个最小入口文件 `example_tmux.conf`，新增 `themes/kmux-base.conf` 负责基础视觉风格，新增 `keybindings/kmux-keys.conf` 负责推荐快捷键。迁移只覆盖 sidebar/workspace-first 工作流与通用基础主题，不依赖 oh-my-tmux、插件或个人环境变量。

**Tech Stack:** tmux config, shell regress, clean tmux server verification

---

## Chunk 1: File Layout and Entry Config

### Task 1: 为示例配置迁移写红测

**Files:**
- Modify: `/Users/KaiHe/workspace/ai_prj/kmux/regress/sidebar-state.sh`

- [ ] **Step 1: 写入口示例配置红测**

在 `sidebar-state.sh` 末尾增加一组 clean-config 断言：

- `source-file /Users/KaiHe/workspace/ai_prj/kmux/example_tmux.conf` 不报错
- `show-options -g mouse` 结果为 `mouse on`
- `list-keys` 中存在：
  - `bind-key -T root M-s focus-sidebar`
  - `bind-key -T root M-S choose-tree -s`

- [ ] **Step 2: 运行红测**

Run: `sh regress/sidebar-state.sh`
Expected: FAIL，因为当前 `example_tmux.conf` 仍是旧 tmux 示例文件，不会 source 新的分层配置。

### Task 2: 重写入口示例文件

**Files:**
- Modify: `/Users/KaiHe/workspace/ai_prj/kmux/example_tmux.conf`
- Create: `/Users/KaiHe/workspace/ai_prj/kmux/themes/kmux-base.conf`
- Create: `/Users/KaiHe/workspace/ai_prj/kmux/keybindings/kmux-keys.conf`

- [ ] **Step 1: 最小化重写 `example_tmux.conf`**

让入口文件只保留：

- 顶部说明注释
- `set-option -sa terminal-features ",xterm*:RGB"`
- `set -g default-terminal "tmux-256color"`
- 两条 `source-file`：

```tmux
source-file "#{current_file_path}/themes/kmux-base.conf"
source-file "#{current_file_path}/keybindings/kmux-keys.conf"
```

如需兼容 `current_file_path` 不可用，改用相对路径并在注释中明确必须从项目根 source。

- [ ] **Step 2: 运行红测确认仍失败在缺失子文件**

Run: `sh regress/sidebar-state.sh`
Expected: FAIL，报找不到 `themes/kmux-base.conf` 或 `keybindings/kmux-keys.conf`，证明入口已指向新结构。

## Chunk 2: Base Theme

### Task 3: 基础主题红测

**Files:**
- Modify: `/Users/KaiHe/workspace/ai_prj/kmux/regress/sidebar-redraw.sh`

- [ ] **Step 1: 写基础主题红测**

在 clean config 场景下 source `example_tmux.conf` 后，断言：

- `show-options -g status-position` 为 `bottom`（或计划里选定的默认值）
- `show-options -g status-style` 包含蓝灰主题色
- `show-options -g pane-active-border-style` 与主题主色一致

只断言通用基础项，不断言具体 icon 或用户主机信息。

- [ ] **Step 2: 运行红测**

Run: `sh regress/sidebar-redraw.sh`
Expected: FAIL，因为主题文件还不存在或未设置这些样式。

### Task 4: 实现 `themes/kmux-base.conf`

**Files:**
- Create: `/Users/KaiHe/workspace/ai_prj/kmux/themes/kmux-base.conf`

- [ ] **Step 1: 写最小基础主题**

主题内容只覆盖通用基础项：

- `status-position bottom`
- `status-style`
- `status-left-length`, `status-right-length`
- `status-left`, `status-right`
- `window-status-format`
- `window-status-current-format`
- `pane-border-style`
- `pane-active-border-style`
- `message-style`
- `mode-style`
- `set -g mouse on`

视觉方向按“冷静蓝灰”：

- 深色背景
- 蓝色作为当前高亮 / active border / 当前窗口主色
- 不依赖 nerd-font；即使没有图标也清晰

- [ ] **Step 2: 运行主题红测**

Run: `sh regress/sidebar-redraw.sh`
Expected: PASS

## Chunk 3: Keybindings

### Task 5: 快捷键迁移红测

**Files:**
- Modify: `/Users/KaiHe/workspace/ai_prj/kmux/regress/sidebar-input.sh`

- [ ] **Step 1: 写 clean-config 快捷键红测**

在 `source-file example_tmux.conf` 场景下验证：

- `M-s` 等价于 `focus-sidebar`
- `focus-sidebar` 再触发一次会退出 sidebar 焦点
- `M-S` 对应 `choose-tree -s`

如果 `send-keys -K` 难以稳定发出 `M-s`，至少用 `list-keys` 精确断言配置文件 source 后的 root 绑定结果。

- [ ] **Step 2: 运行红测**

Run: `sh regress/sidebar-input.sh`
Expected: FAIL，因为 `keybindings/kmux-keys.conf` 还不存在。

### Task 6: 实现 `keybindings/kmux-keys.conf`

**Files:**
- Create: `/Users/KaiHe/workspace/ai_prj/kmux/keybindings/kmux-keys.conf`

- [ ] **Step 1: 写最小快捷键集**

迁入这些键：

```tmux
bind-key -n M-s focus-sidebar
bind-key -n M-S choose-tree -s
bind-key -n M-r command-prompt -I "#S" "rename-session '%%'"
bind-key -n M-n new-session
bind-key -n M-x detach-client
bind-key -n M-t new-window -c "#{pane_current_path}"
bind-key -n M-w kill-pane
bind-key -n M-f resize-pane -Z
bind-key -n M-, command-prompt -I "#W" "rename-window '%%'"
bind-key -n M-1 select-window -t 1
...
bind-key -n M-9 select-window -t 9
bind-key -n M-[ previous-window
bind-key -n M-] next-window
bind-key -n M-d split-window -h -c "#{pane_current_path}"
bind-key -n M-D split-window -v -c "#{pane_current_path}"
```

不要迁入 `M-Left/M-Right/M-Up/M-Down`。

- [ ] **Step 2: 运行快捷键红测**

Run: `sh regress/sidebar-input.sh`
Expected: PASS

## Chunk 4: Final Verification and Docs

### Task 7: 更新文档说明

**Files:**
- Modify: `/Users/KaiHe/workspace/ai_prj/kmux/docs/superpowers/specs/2026-03-23-example-tmux-config-migration-design.md`
- Modify: `/Users/KaiHe/workspace/ai_prj/kmux/findings.md`
- Modify: `/Users/KaiHe/workspace/ai_prj/kmux/progress.md`
- Modify: `/Users/KaiHe/workspace/ai_prj/kmux/task_plan.md`

- [ ] **Step 1: 补充已实现文件路径和验证命令**

把最终落地的文件、保留/未迁入的快捷键边界、验证命令回写到文档和 planning 文件。

- [ ] **Step 2: 不做额外功能扩展**

保持 YAGNI，不顺手加第二套主题、终端专用 preset 或插件配置。

### Task 8: 串行验证

**Files:**
- Test: `/Users/KaiHe/workspace/ai_prj/kmux/regress/sidebar-state.sh`
- Test: `/Users/KaiHe/workspace/ai_prj/kmux/regress/sidebar-input.sh`
- Test: `/Users/KaiHe/workspace/ai_prj/kmux/regress/sidebar-redraw.sh`

- [ ] **Step 1: 运行构建**

Run: `make -j2`
Expected: exit 0

- [ ] **Step 2: 运行关键回归**

Run:

```bash
sh regress/sidebar-state.sh
sh regress/sidebar-input.sh
sh regress/sidebar-redraw.sh
sh regress/sidebar-click-switch.sh
sh regress/sidebar-mouse.sh
sh regress/sidebar-switch-reflow.sh
```

Expected: PASS

- [ ] **Step 3: 手工 smoke 测试**

Run:

```bash
./tmux -Lkmux-example kill-server 2>/dev/null || true
./tmux -Lkmux-example -f /Users/KaiHe/workspace/ai_prj/kmux/example_tmux.conf new-session -d -s alpha -x 100 -y 30
./tmux -Lkmux-example -f /Users/KaiHe/workspace/ai_prj/kmux/example_tmux.conf new-session -d -s beta -x 100 -y 30
./tmux -Lkmux-example -f /Users/KaiHe/workspace/ai_prj/kmux/example_tmux.conf attach -t alpha
```

手动确认：

- 默认就是蓝灰基础主题
- `Option + s` 进入/退出 sidebar 焦点
- `Option + Shift + s` 打开 chooser
- `Option + t/d/D/w/f/[ / ]/1..9` 行为正常

- [ ] **Step 4: Commit**

```bash
git add example_tmux.conf themes/kmux-base.conf keybindings/kmux-keys.conf regress/sidebar-state.sh regress/sidebar-input.sh regress/sidebar-redraw.sh docs/superpowers/specs/2026-03-23-example-tmux-config-migration-design.md docs/superpowers/plans/2026-03-23-example-tmux-config-migration.md task_plan.md findings.md progress.md
git commit -m "feat: migrate example tmux config for kmux"
```
