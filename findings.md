# Findings

## 仓库现状

- 仓库路径：`/Users/KaiHe/workspace/ai_prj/kmux`
- 当前分支：`kai.he-x/sidebar-prd`
- remote 已配置：
  - `origin git@github.com:Heelc/kmux.git`
- 已初始化 `bd`：
  - 数据库：`.beads/beads.db`
  - 当前 issue 前缀：`kmux-`

## 背景来源

- 本轮背景研究来自 `x-workspace` 项目里围绕“左栏固定 + 右栏原生 tmux”的多轮实验。
- 已证明：
  - `Textual + Rich + pyte` 路线可以验证交互状态机
  - 但无法稳定达到原生 tmux 的性能和手感
- 量化结论：
  - 直接 `PTYTerminalHost + tmux attach-session` 路径约 `0.20s`
  - 外层 Rich 整屏彩色渲染单帧约 `18ms`
  - 性能瓶颈在外层宿主，不在 tmux

## tmux 源码级结论

- `choose-tree`/`choose-client`/`choose-buffer` 不是常驻侧栏组件，而是把目标 pane 切进一个 window mode。
- `cmd-choose-tree.c` 的 `cmd_choose_tree_exec()` 最终调用 `window_pane_set_mode(...)`。
- `window-tree.c` 的 `window_tree_init()` 再调用 `mode_tree_start(...)` 启动 tree mode。
- `mode-tree.c` 说明这是一整套 pane 内树形 mode：
  - 自带树数据结构
  - 自带搜索、过滤、tag、preview
  - 自带 `j/k/g/G/h/l` 等交互语义
- `screen-redraw.c` 的 `screen_redraw_screen()` 说明 tmux 采用 client 统一重绘：
  - panes
  - borders
  - status
  - overlay
- `server-client.c` 说明输入也是 client 统一分发：
  - overlay
  - prompt
  - key table
  - pane mode
  - 最后才到 `window_pane_key(...)`

## 直接推论

- 想要“左栏常驻 + 右栏原生 tmux”：
  - 不能只复用 `choose-tree`
  - 也不能只加一个 command
- 最小正确方向是 fork tmux，并增加：
  - 原生 sidebar 布局区域
  - sidebar 焦点
  - sidebar 键盘/鼠标路由
  - sidebar 与右侧 client 视图的联合重绘

## 备选路线

- 方案 A：fork tmux，做原生 sidebar
  - 最符合目标
  - 性能最好
  - 维护成本最高
- 方案 B：用 control mode 做外部壳
  - 工程风险较低
  - 但仍然不是“tmux 本体内建 sidebar”
- 方案 C：继续外层 Textual/TUI
  - 已证明不符合性能与交互目标
  - 不建议继续投入

## beads 任务主线

- feature：
  - `kmux-1n6` `Native sidebar MVP`
- ready tasks：
  - `kmux-0c3` `Add client sidebar state and config surface`
  - `kmux-e5d` `Render native sidebar region in client redraw`
  - `kmux-cr0` `Route sidebar keyboard and mouse input in server client`
  - `kmux-jl1` `Reuse window tree and mode tree for sidebar data model`

## AGENTS 约定

- 已在仓库根新增并更新 `AGENTS.md`
- 约定新的 agent 进入仓库后：
  - 先跑 `bd prime`
  - 再跑 `bd ready`
  - 开始编码前先 `bd show` + `bd update <id> --status=in_progress`
- 当前 native sidebar 主线先看：
  - `docs/native-sidebar-research.md`
  - `docs/native-sidebar-prd.md`

## 本轮复核结论

- 要做的不是“把 chooser 常驻化”，而是给 `kmux` 增加一个 client 级原生 sidebar。
- MVP 的产品目标非常明确：
  - 左侧常驻 session/workspace 列表
  - 右侧保持 tmux 原生 pane/window/status bar 行为
  - 不引入明显性能损耗
  - 支持鼠标和 vim 风格键位
- 第一版术语映射已经定死：
  - `Workspace = session`
  - `Terminal = window`
  - `Split = pane`
- 第一版只做导航，不做右侧 detail、AI attention、复杂预览或拖拽排序。
- 交互最小闭环是：
  - 键盘 `j/k/g/G/Enter`
  - 鼠标单击高亮、双击切换
  - `Ctrl-b` 等 prefix 继续服务右侧原生 tmux
- 技术实现不是往 pane mode 里塞 sidebar，而是同时改 4 个核心面：
  - `tmux.h` / `struct client`
  - `screen-redraw.c`
  - `server-client.c`
  - `window-tree.c` + `mode-tree.c`
- beads 中 4 个 ready task 与 PRD Phase 1-4 基本一一对应：
  - `kmux-0c3` 对应状态面
  - `kmux-e5d` 对应绘制面
  - `kmux-cr0` 对应输入面
  - `kmux-jl1` 对应数据与交互复用面
- `kmux-1n6` 是聚合 feature，依赖以上 4 个子任务完成后才算 MVP 闭环。

## 代码级设计边界

- `struct client` 是 sidebar 运行时状态的正确挂载点，定义位于 `tmux.h`，并且已经承载：
  - overlay
  - prompt
  - click/double-click 状态
  - redraw flags
- `screen_redraw_screen()` 是 client 全屏绘制总入口，左栏固定区域必须从这里切入，而不是从 pane mode 侧面插入。
- `server_client_handle_key()` 只做即时特例处理后把按键排入命令队列，因此 sidebar 键盘路由要么在这里拦截，要么在其 callback 路径中早于 pane 输入分发处理。
- `window_tree_init()` 和 `mode_tree_start()` 目前都显式绑定 `window_pane`/`window_mode_entry` 生命周期。
- 直接把 `mode-tree` 当 sidebar 视图嵌进 client 区域并不现实；更合理的是：
  - MVP 先复用其数据模型、排序/过滤/导航语义
  - 再决定后续是否抽公共适配层

## 设计访谈已确认决策

- sidebar 开关采用两层模型：
  - `session` 提供默认值
  - `client` 允许本地 override
- client override 生命周期采用双命令语义：
  - 临时切换只影响当前 client attach 生命周期
  - 显式“设为默认”才写回 session 配置
- client 初始化 sidebar 显示状态时：
  - 先读 session 默认值
  - 再应用 client override
- 窄终端不自动隐藏 sidebar：
  - 允许 sidebar 退化到最小宽度
  - 不改变“sidebar 可见”的语义
- 焦点模型采用：
  - 键盘显式进入 sidebar 导航模式
  - 鼠标点击左栏也可取得 sidebar 焦点
  - `Enter` 完成切换后回到右侧
  - 退出动作单独设计
- 键盘进入 sidebar 的入口采用：
  - 先提供显式命令，例如 `focus-sidebar`
  - MVP 不抢占 tmux 现有默认键位
- 左栏列表层级收敛为：
  - MVP 只显示 `session` 一层
  - 不在第一版展开 `window/pane`
- sidebar 宽度策略收敛为：
  - 不做每次 redraw 的内容自适应
  - 不做持续比例联动
  - 采用稳定列宽
  - 当前默认值定为：`default=24`, `min=20`, `max=32`
- sidebar 条目内容采用：
  - 单行 session 列表
  - 显示 session 名
  - 显示当前 session 标记
  - 显示当前高亮样式
  - 后续可预留 agent 状态标记槽，但不进 MVP
- 当 sidebar 进入浏览态时：
  - `current session` 与 `selected item` 允许分离
  - 当前 session 标记与当前高亮可同时出现在不同条目
- 命令面 MVP 先收敛为：
  - `focus-sidebar`
  - `toggle-sidebar`
  - `set-sidebar-default`
- 若在 sidebar 浏览时关闭 sidebar：
  - 只收起 UI
  - 不提交当前选择
  - 焦点回右侧 tmux
- 鼠标滚轮命中左栏时：
  - 优先作用于 sidebar 列表，不透传右侧 pane
- 左右区域之间：
  - 需要明确分隔线
  - 样式尽量复用 tmux 现有 border 风格
- 绘制实现边界倾向于：
  - 从 `screen_redraw_screen()` 调独立 sidebar 模块
  - 不把全部逻辑继续堆进 `screen-redraw.c`

## 正式设计文档

- 已输出 spec：
  - `docs/superpowers/specs/2026-03-20-native-sidebar-mvp-design.md`
- 文档覆盖内容包括：
  - 交互模型
  - 状态模型
  - option/runtime 边界
  - 命令面
  - 渲染与输入模块边界
  - `mode-tree/window-tree` 复用边界
  - beads 任务映射与验证策略

## 正式实现计划

- 已输出 implementation plan：
  - `docs/superpowers/plans/2026-03-20-native-sidebar-mvp.md`
- 计划特点：
  - 按 `kmux-0c3` / `kmux-e5d` / `kmux-cr0` / `kmux-jl1` 的顺序拆解
  - 为每一块给出 create/modify/test 文件清单
  - 为每个阶段给出构建命令、regress 脚本和预期结果
  - 明确新增 `cmd-sidebar.c`、`sidebar.c`、`sidebar.h`
  - 明确构建接线点在 `Makefile.am` 与 `cmd.c`
