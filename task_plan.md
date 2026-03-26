# kmux 原生 Sidebar 规划

## 目标

- 把本轮关于“fork tmux 实现原生左侧 workspace/session sidebar”的研究背景和产品需求落到 `kmux` 仓库。
- 为下一次开发 thread 提供可直接接手的上下文，而不是再次从 `x-workspace` 的实验路线回溯。

## 当前阶段

- [x] 盘点 `Heelc/sidebar-audit` 相对 `master` 的提交与功能增量
- [x] 定位 `kmux` 仓库并确认当前分支/remote 状态
- [x] 建立项目内 planning 文件
- [x] 输出研究背景文档
- [x] 输出 PRD 文档
- [x] 复查文档结构与要点完整性
- [x] 本地提交文档变更
- [x] 初始化 `bd` 并创建 native sidebar 主线 issue
- [x] 更新 `AGENTS.md`，明确下个 agent 的 `bd` 工作流入口
- [x] 复核 `docs/native-sidebar-research.md`、`docs/native-sidebar-prd.md` 与 beads 任务拆分
- [x] 整理当前 MVP 的目标、范围、实现顺序与依赖关系
- [x] 通过 `grill-me` 完成 native sidebar MVP 的实现设计访谈
- [x] 输出正式设计文档到 `docs/superpowers/specs/`
- [x] 输出正式实现计划到 `docs/superpowers/plans/`
- [x] 为 worktree 补齐 autotools 环境并打通基线构建
- [x] 完成 Chunk 1：state、options、commands 与 state regression
- [x] 完成 Chunk 2：sidebar redraw 与宽度裁剪
- [x] 完成 Chunk 3：sidebar 键盘/鼠标输入路由
  - [x] 键盘白名单路由与回归
  - [x] 鼠标命中、滚轮与双击提交
- [x] 完成 Chunk 4：复用边界确认、额外安全网与收尾
  - [x] sidebar 选择/绘制顺序与现有 session 排序 helper 对齐
  - [x] 记录 broader regress 结果与 automation gap
- [x] 处理 code review 阻塞项并补齐鼠标回归
  - [x] 修正 sidebar 可见时右侧 pane 鼠标坐标换算
  - [x] 修正极窄终端下的 sidebar fallback 语义
  - [x] 稳定 `sidebar-mouse.sh`，覆盖真实 attach client 的鼠标命中
- [x] 完成 sidebar 快捷键手感优化
  - [x] 收敛默认 `M-s/M-S` 方案
  - [x] 调整 `focus-sidebar` 为可进可退的 toggle 语义
  - [x] 补齐快捷键回归与快捷键设计/计划文档
- [x] 完成项目示例 tmux 配置迁移设计
  - [x] 收敛迁移范围为基础主题 + 高频 Option 快捷键
  - [x] 确认采用分层示例配置结构
  - [x] 输出 example config migration spec
- [x] 输出项目示例 tmux 配置迁移实现计划
- [x] 完成项目示例 tmux 配置迁移实现
  - [x] 重写 `example_tmux.conf` 为分层入口
  - [x] 新增 `themes/kmux-base.conf`
  - [x] 新增 `keybindings/kmux-keys.conf`
  - [x] 补齐 clean-config 回归并验证

## 关键决策

- 不再把当前 `x-workspace` 的 `Textual + Rich` 右侧终端宿主当作长期方案。
- `kmux` 的目标应以 “左侧常驻导航 + 右侧原生 tmux” 为主，不额外引入会显著影响性能的外层终端渲染宿主。
- 第一版优先做原生性能和交互正确性，美观和 AI agent 提示后置。

## 待交付文件

- `docs/native-sidebar-research.md`
- `docs/native-sidebar-prd.md`
- `docs/superpowers/specs/2026-03-20-native-sidebar-mvp-design.md`
- `docs/superpowers/specs/2026-03-23-example-tmux-config-migration-design.md`
- `docs/superpowers/plans/2026-03-20-native-sidebar-mvp.md`
- `docs/superpowers/plans/2026-03-23-example-tmux-config-migration.md`
- `example_tmux.conf`
- `themes/kmux-base.conf`
- `keybindings/kmux-keys.conf`
- `findings.md`
- `progress.md`

## 风险

- `choose-tree` 并不是现成 sidebar 组件，不能低估改造成本。
- 要做到左栏常驻，必须改 `client` 重绘和输入分发，而不是只加一个 command。
- fork tmux 会带来长期维护成本，需要在 PRD 中明确“最小可行改动面”。

## 当前执行顺序

1. `kmux-0c3`
   - 建立 `struct client` 上的 sidebar 状态、开关和选择项。
2. `kmux-e5d`
   - 在 `screen-redraw.c` 中切出左侧固定区域，并保证右侧 pane 视图维持原样。
3. `kmux-cr0`
   - 在 `server-client.c` 中接管 sidebar 的键盘和鼠标命中，再把右侧输入保持为 tmux 原生路径。
4. `kmux-jl1`
   - 把 `mode-tree/window-tree` 的数据和交互语义接进 sidebar，而不是自造一套树实现。

## 当前执行备注

- 2026-03-26 分支盘点结论：
  - 相对 `master` 共新增 7 个非 merge 提交
  - 主体功能不是单纯 PRD，而是已经落地原生 sidebar MVP、交互打磨和示例配置迁移
  - 代码变更集中在 `sidebar.c/.h`、`cmd-sidebar.c`、`server-client.c`、`screen-redraw.c`、`tty.c`、`options-table.c`、`example_tmux.conf` 与多条 `regress/sidebar-*.sh`
- `kmux-cr0` 已完成：
  - `j/k/g/G/Enter/Escape` 在 sidebar focus 下由 sidebar 消费
  - 非白名单键继续走 tmux 原生 key binding
  - 左栏单击高亮并取焦
  - 左栏双击切换 session
  - 左栏滚轮滚动 selection
- `kmux-jl1` 当前结论：
  - sidebar 已直接复用 `sort_get_sessions()`、`session_next_session()`、`session_previous_session()`
  - 不需要为了 MVP 把 `window-tree.c`/`mode-tree.c` 抽成新的 client 级公共组件
  - 额外要做的是把这一复用边界和 broader regress 结果记录清楚
- code review 跟进已完成：
  - `server_client_check_mouse()` 在 pane 命中前先扣除 `sidebar_client_offset()`
  - divider 列不再落入 pane 命中路径
  - 极窄终端下 `sidebar_client_width()` 会临时返回 `0`，优先保住右侧 `20` 列 pane 区
  - `regress/sidebar-mouse.sh` 现在用真实 detach 流程而不是 `Ctrl-C`，并支持 `make -C regress` 下的二进制路径
- handoff 后的真实手工测试修复已完成：
  - sidebar 切到 detached session 时，不再让旧 pane 历史在收窄后 reflow 成多行
  - 修复范围只落在 sidebar 提交路径，不改变普通 `switch-client` 和常规 resize 语义
  - 已新增 `regress/sidebar-switch-reflow.sh` 作为专门回归
- 快捷键 UX 当前结论：
  - `Option + s` 默认进入 sidebar 焦点；若已在 sidebar 焦点则退出
  - `Option + Shift + s` 保留原 session chooser
  - `j/k/g/G` 在 sidebar 焦点内继续“移动即切换”，焦点停留在 sidebar
- 示例配置迁移当前结论：
  - `example_tmux.conf` 只做入口和少量通用基础项
  - 新增 `themes/kmux-base.conf` 承载基础主题
  - 新增 `keybindings/kmux-keys.conf` 承载项目默认快捷键
  - 主题方向采用“冷静蓝灰”，不依赖 oh-my-tmux
- 示例配置迁移当前实现状态：
  - 已在 `sidebar-mvp-impl` worktree 上完成
  - `example_tmux.conf` 通过 `source-file -F "#{d:current_file}/..."` 加载子文件
  - clean-config 下已能提供蓝灰主题和高频 `Option` 快捷键
