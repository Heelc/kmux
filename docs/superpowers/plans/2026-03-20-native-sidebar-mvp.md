# Native Sidebar MVP Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 为 `kmux` 实现原生左侧 session sidebar MVP，保持右侧 tmux 原生操作流和性能体验。

**Architecture:** 方案以 client 级 sidebar 为核心：运行时状态挂在 `struct client`，持久默认值挂在 session/global session options，左栏渲染从 `screen_redraw_screen()` 进入，键盘和鼠标命中在 `server-client.c` 中走窄白名单路由。MVP 只做 session 一层列表，不做 pane mode 通用化重构，也不把 `mode-tree` 直接嵌入 client 区域。

**Tech Stack:** C, autotools (`autogen.sh`, `configure`, `make`), tmux options/commands/key bindings, shell regress harness (`regress/*.sh`)

---

## File Map

### Create

- `cmd-sidebar.c`
  - 新增 `focus-sidebar`、`toggle-sidebar`、`set-sidebar-default` 命令。
- `sidebar.c`
  - sidebar 宽度计算、session 列表遍历、选择状态同步、切换帮助函数。
- `sidebar.h`
  - sidebar 对外声明，供 `screen-redraw.c` 和 `server-client.c` 调用。
- `regress/sidebar-state.sh`
  - 验证 session default、client override 和命令面行为。
- `regress/sidebar-redraw.sh`
  - 验证左栏常驻、宽度裁剪、右侧 pane 仍可见。
- `regress/sidebar-input.sh`
  - 验证键盘白名单、prefix 保留、鼠标单击/双击/滚轮路由。

### Modify

- `Makefile.am`
  - 把 `cmd-sidebar.c`、`sidebar.c`、`sidebar.h` 接进构建。
- `cmd.c`
  - 注册新的 sidebar 命令 entry。
- `tmux.h`
  - 增加 `struct client_sidebar_state` 和 sidebar 辅助函数声明。
- `options-table.c`
  - 增加 session/global session 持久默认值选项。
- `options.c`
  - 仅在需要额外 helper 时修改；能复用现有 options 逻辑就不要扩散。
- `client.c`
  - 在 client 初始化/销毁路径中初始化 sidebar runtime state。
- `server-client.c`
  - sidebar 键盘与鼠标命中路由、切换和 focus 状态流转。
- `screen-redraw.c`
  - 从主 redraw 入口调用 sidebar 绘制并调整右侧可用区域。
- `cmd-switch-client.c`
  - 如需要，在切 session 后补一个 sidebar current/selected 同步入口，避免逻辑散在多处。
- `window-tree.c`
  - 仅在提取可复用排序/遍历逻辑时修改；不要把 pane mode 生命周期改成 client 组件。

### Generated / Do Not Edit By Hand

- `configure`
- `Makefile`
- `cmd-parse.c`

更新 `Makefile.am` 后，统一通过 `sh autogen.sh && ./configure --disable-utf8proc && make` 生成与编译。

## Chunk 1: State, Options, and Commands

### Task 1: Add Sidebar Runtime State to Client

**Files:**
- Modify: `tmux.h`
- Modify: `client.c`
- Modify: `Makefile.am`
- Test: `regress/sidebar-state.sh`

- [ ] **Step 1: Write the failing state regression scaffold**

Create `regress/sidebar-state.sh` with checks for:

- `set-option -g sidebar on` changes default for a new session
- `toggle-sidebar` only affects the current client
- `focus-sidebar` is accepted as a tmux command

- [ ] **Step 2: Run the new regression to verify it fails**

Run:

```bash
make -C regress sidebar-state.sh
```

Expected:

- FAIL because the sidebar commands and options do not exist yet.

- [ ] **Step 3: Add the runtime state structure**

In `tmux.h`, add a nested structure similar to:

```c
struct client_sidebar_state {
	int visible;
	int focus;
	u_int width;
	int has_override;
	int override_visible;
	int selected_session_id;
};
```

Then embed it inside `struct client`.

- [ ] **Step 4: Initialize runtime state in client lifecycle**

In `client.c`:

- zero-initialize sidebar state on client creation
- set default width to `24`
- set `selected_session_id` to “no selection yet”

- [ ] **Step 5: Wire new source files into the build**

In `Makefile.am`, add:

- `cmd-sidebar.c`
- `sidebar.c`
- `sidebar.h`

- [ ] **Step 6: Rebuild to catch header and source list mistakes early**

Run:

```bash
sh autogen.sh && ./configure --disable-utf8proc && make
```

Expected:

- build still fails, but now due to missing command/sidebar implementations rather than undefined client struct members.

- [ ] **Step 7: Commit the client state scaffold**

```bash
git add Makefile.am tmux.h client.c regress/sidebar-state.sh
git commit -m "feat: add client sidebar state scaffold"
```

### Task 2: Add Session Defaults and Sidebar Commands

**Files:**
- Create: `cmd-sidebar.c`
- Modify: `cmd.c`
- Modify: `options-table.c`
- Modify: `tmux.h`
- Modify: `sidebar.h`
- Modify: `sidebar.c`
- Test: `regress/sidebar-state.sh`

- [ ] **Step 1: Extend the failing regression with exact command assertions**

Add shell checks for:

- `set-option -g sidebar on`
- `show-options -g sidebar`
- `focus-sidebar`
- `toggle-sidebar`
- `set-sidebar-default on`

- [ ] **Step 2: Run the regression and verify the exact failure mode**

Run:

```bash
make -C regress sidebar-state.sh
```

Expected:

- FAIL with errors such as unknown option `sidebar` or unknown command `focus-sidebar`.

- [ ] **Step 3: Add session/global session options**

In `options-table.c`, add session-scoped entries for:

- `sidebar`
- `sidebar-width`

Constraints:

- `sidebar` default `off`
- `sidebar-width` default `24`, min `20`, max `32`

- [ ] **Step 4: Add sidebar helper APIs**

In `sidebar.h` / `sidebar.c`, add helpers for:

- reading persistent default from session options
- computing effective client visibility from session default + override
- clearing client override
- applying client-local toggle

- [ ] **Step 5: Implement sidebar commands**

In `cmd-sidebar.c` implement:

- `focus-sidebar`
- `toggle-sidebar`
- `set-sidebar-default`

Rules:

- commands must use standard tmux `cmd_entry`
- `set-sidebar-default` should support `-g` via session/global session options
- `toggle-sidebar` must not write to options
- `focus-sidebar` only changes current client runtime state

- [ ] **Step 6: Register the commands**

In `cmd.c`, add:

- `extern` declarations
- `cmd_table[]` entries

- [ ] **Step 7: Rebuild and run the state regression**

Run:

```bash
sh autogen.sh && ./configure --disable-utf8proc && make
make -C regress sidebar-state.sh
```

Expected:

- build succeeds
- `sidebar-state.sh` passes

- [ ] **Step 8: Commit the option and command layer**

```bash
git add cmd-sidebar.c cmd.c options-table.c sidebar.c sidebar.h tmux.h regress/sidebar-state.sh
git commit -m "feat: add sidebar options and commands"
```

## Chunk 2: Rendering and Layout

### Task 3: Add Sidebar Layout Helpers and Width Clamping

**Files:**
- Create: `sidebar.c`
- Create: `sidebar.h`
- Modify: `tmux.h`
- Modify: `screen-redraw.c`
- Test: `regress/sidebar-redraw.sh`

- [ ] **Step 1: Write the failing redraw regression**

Create `regress/sidebar-redraw.sh` with checks for:

- sidebar visible when session option is on
- sidebar width defaults to `24`
- right pane remains visible after sidebar is enabled
- when client width is narrow, sidebar clamps but right side still retains `pane_min = 20`

- [ ] **Step 2: Run the redraw regression to verify failure**

Run:

```bash
make -C regress sidebar-redraw.sh
```

Expected:

- FAIL because sidebar is not yet drawn and no width clamping exists.

- [ ] **Step 3: Implement geometry helpers**

In `sidebar.c`, add helpers for:

- computing effective width
- clamping width to `20..32`
- shrinking sidebar first during resize pressure
- preserving right pane minimum width `20`

- [ ] **Step 4: Define a clean redraw interface**

In `sidebar.h`, define a small redraw-facing API such as:

- `sidebar_visible(struct client *)`
- `sidebar_width(struct client *, u_int tty_sx)`
- `sidebar_draw(struct screen_redraw_ctx *)`

Avoid leaking list internals into `screen-redraw.c`.

- [ ] **Step 5: Call sidebar drawing from the main redraw path**

In `screen-redraw.c`:

- calculate sidebar geometry before pane drawing
- reserve left-side space
- draw the vertical divider
- keep status/overlay behavior consistent with existing redraw flow

- [ ] **Step 6: Keep the right side native**

Verify pane drawing still runs through existing pane redraw helpers. The sidebar task must not fork or duplicate pane rendering logic.

- [ ] **Step 7: Build and run the redraw regression**

Run:

```bash
sh autogen.sh && ./configure --disable-utf8proc && make
make -C regress sidebar-redraw.sh
```

Expected:

- build succeeds
- `sidebar-redraw.sh` passes

- [ ] **Step 8: Commit the layout and redraw work**

```bash
git add sidebar.c sidebar.h screen-redraw.c regress/sidebar-redraw.sh
git commit -m "feat: render native sidebar region"
```

### Task 4: Draw Session Rows with Current and Selected State

**Files:**
- Modify: `sidebar.c`
- Modify: `sidebar.h`
- Modify: `server-client.c`
- Test: `regress/sidebar-redraw.sh`

- [ ] **Step 1: Extend the redraw regression for row semantics**

Add checks for:

- current session marker is shown
- selected row is visually distinct
- current and selected can diverge while browsing

- [ ] **Step 2: Run the regression and verify failure**

Run:

```bash
make -C regress sidebar-redraw.sh
```

Expected:

- FAIL because row state rendering is incomplete.

- [ ] **Step 3: Implement session list traversal**

In `sidebar.c`, enumerate current sessions on demand for each redraw instead of maintaining a cache.

Rules:

- render only session layer
- no window/pane expansion
- keep row-building code ready for future right-side status markers

- [ ] **Step 4: Implement dual state rendering**

Render:

- `current` session marker
- `selected` highlight
- optional attached marker

Make sure `selected` falls back to `current` when sidebar focus is inactive.

- [ ] **Step 5: Sync selected state after client session switch**

In `server-client.c` or a sidebar helper called from there:

- after a successful session switch, sync `selected_session_id` to the new current session

- [ ] **Step 6: Re-run redraw validation**

Run:

```bash
make -C regress sidebar-redraw.sh
```

Expected:

- PASS with current/selected behavior covered

- [ ] **Step 7: Commit row rendering semantics**

```bash
git add sidebar.c sidebar.h server-client.c regress/sidebar-redraw.sh
git commit -m "feat: draw sidebar session rows"
```

## Chunk 3: Input Routing and Session Switching

### Task 5: Route Keyboard Input Through a Sidebar Whitelist

**Files:**
- Modify: `server-client.c`
- Modify: `sidebar.c`
- Modify: `sidebar.h`
- Test: `regress/sidebar-input.sh`

- [ ] **Step 1: Write the failing keyboard regression**

Create `regress/sidebar-input.sh` with checks for:

- `focus-sidebar` enables sidebar navigation state
- `j/k/g/G` change selection only
- `Enter` switches the current client session
- `Esc` cancels selection without switching
- `Ctrl-b` and custom bindings still work while sidebar focus is active

- [ ] **Step 2: Run the keyboard regression to verify failure**

Run:

```bash
make -C regress sidebar-input.sh
```

Expected:

- FAIL because sidebar focus and whitelist routing are not implemented yet.

- [ ] **Step 3: Add narrow keyboard routing helpers**

In `sidebar.c`, add helpers like:

- `sidebar_has_focus(struct client *)`
- `sidebar_handle_key(struct client *, struct key_event *)`

Behavior:

- only intercept `j/k/g/G/Enter/Esc`
- return “not handled” for all other keys

- [ ] **Step 4: Wire the whitelist into client key handling**

In `server-client.c`, insert sidebar routing before pane input, but after existing overlay/prompt special cases.

Critical rule:

- if the key is not in the sidebar whitelist, continue into tmux’s original key flow untouched

- [ ] **Step 5: Reuse tmux session switching instead of inventing a new switch path**

For `Enter`, reuse the existing client session switch semantics, targeting only the current client.

If the cleanest route is a shared helper, extract one; do not duplicate `switch-client` business logic.

- [ ] **Step 6: Build and run the keyboard regression**

Run:

```bash
sh autogen.sh && ./configure --disable-utf8proc && make
make -C regress sidebar-input.sh
```

Expected:

- build succeeds
- `sidebar-input.sh` passes

- [ ] **Step 7: Commit keyboard routing**

```bash
git add server-client.c sidebar.c sidebar.h regress/sidebar-input.sh
git commit -m "feat: route sidebar keyboard input"
```

### Task 6: Route Mouse Click, Double-Click, and Wheel Input

**Files:**
- Modify: `server-client.c`
- Modify: `sidebar.c`
- Modify: `sidebar.h`
- Test: `regress/sidebar-input.sh`

- [ ] **Step 1: Extend the input regression for mouse behavior**

Add checks for:

- single click selects and focuses a row
- double click switches session
- wheel events over sidebar move the sidebar selection/list rather than the pane
- mouse on the right side still reaches pane behavior

- [ ] **Step 2: Run the regression and verify failure**

Run:

```bash
make -C regress sidebar-input.sh
```

Expected:

- FAIL because mouse hit-testing and routing are incomplete.

- [ ] **Step 3: Add sidebar hit-testing helpers**

In `sidebar.c`, implement:

- point-in-sidebar test
- row-from-mouse-position mapping
- click/double-click handlers
- wheel handler

- [ ] **Step 4: Route mouse events by hit region**

In `server-client.c`:

- if the event hits the sidebar, consume it there
- otherwise leave existing tmux pane mouse flow intact

- [ ] **Step 5: Preserve cancel semantics**

Ensure:

- single click does not switch session
- double click does switch session
- hiding the sidebar still does not auto-commit selection

- [ ] **Step 6: Re-run input validation**

Run:

```bash
make -C regress sidebar-input.sh
```

Expected:

- PASS with both keyboard and mouse paths covered

- [ ] **Step 7: Commit mouse routing**

```bash
git add server-client.c sidebar.c sidebar.h regress/sidebar-input.sh
git commit -m "feat: route sidebar mouse input"
```

## Chunk 4: Reuse Boundary, Regression Hardening, and Handoff

### Task 7: Align Sidebar Semantics with `mode-tree` Without Refactoring It

**Files:**
- Modify: `sidebar.c`
- Modify: `window-tree.c`
- Modify: `tmux.h`
- Test: `regress/sidebar-redraw.sh`
- Test: `regress/sidebar-input.sh`

- [ ] **Step 1: Identify the minimum reusable logic**

Check whether existing session sorting and traversal helpers can be reused directly. If they cannot be reused cleanly, stop at semantic alignment and document why.

- [ ] **Step 2: Do the smallest possible extraction**

If needed:

- extract only session ordering/traversal helpers
- keep pane mode lifecycle untouched
- do not move preview/filter/menu/help code

- [ ] **Step 3: Keep the sidebar one-level**

Verify that no code path accidentally expands into window/pane rendering or chooser-mode UI.

- [ ] **Step 4: Run targeted regressions**

Run:

```bash
make -C regress sidebar-redraw.sh
make -C regress sidebar-input.sh
```

Expected:

- both pass without introducing tree-mode regressions

- [ ] **Step 5: Commit reuse-boundary cleanup**

```bash
git add sidebar.c window-tree.c tmux.h regress/sidebar-redraw.sh regress/sidebar-input.sh
git commit -m "refactor: align sidebar semantics with mode tree patterns"
```

### Task 8: Full Build, Regression Sweep, and Documentation Sync

**Files:**
- Modify: `findings.md`
- Modify: `progress.md`
- Modify: `task_plan.md`
- Test: `regress/sidebar-state.sh`
- Test: `regress/sidebar-redraw.sh`
- Test: `regress/sidebar-input.sh`

- [ ] **Step 1: Run the full project build**

Run:

```bash
sh autogen.sh && ./configure --disable-utf8proc && make
```

Expected:

- full build succeeds cleanly

- [ ] **Step 2: Run focused regressions**

Run:

```bash
make -C regress sidebar-state.sh
make -C regress sidebar-redraw.sh
make -C regress sidebar-input.sh
```

Expected:

- all three sidebar regressions pass

- [ ] **Step 3: Run a broader safety net**

Run:

```bash
make -C regress session-group-resize.sh
make -C regress input-keys.sh
make -C regress tty-keys.sh
```

Expected:

- no regression in session switching, input routing, or tty key decoding

- [ ] **Step 4: Update planning files**

Record:

- final file list
- test commands run
- any deviations from the spec

- [ ] **Step 5: Final commit**

```bash
git add docs/superpowers/plans/2026-03-20-native-sidebar-mvp.md findings.md progress.md task_plan.md
git commit -m "docs: add native sidebar implementation plan"
```

## Notes for Execution

- Always claim the relevant bead before implementing a chunk.
- Do not edit generated files directly.
- Do not widen the sidebar key whitelist beyond `j/k/g/G/Enter/Esc` in MVP.
- Do not let sidebar override or shadow user key bindings outside that whitelist.
- Prefer helper extraction over logic duplication, but stop before turning this into a `mode-tree` rewrite.
- Keep commits small and aligned with the task boundaries above.
