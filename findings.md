# Findings

## 仓库现状

- 仓库路径：`/Users/KaiHe/workspace/ai_prj/kmux`
- 当前分支：`kai.he-x/sidebar-prd`
- remote 已配置：
  - `origin git@github.com:Heelc/kmux.git`

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
