# kmux 原生 Sidebar 研究背景

## 1. 为什么要做这件事

在 `x-workspace` 的多轮实验中，我们已经验证过一个核心事实：

- 如果目标是“左侧常驻 workspace/session 导航，右侧保留原生终端与 tmux 体验”，
- 那么外层 `Textual + Rich + pyte` 宿主只能作为验证状态机的过渡方案，
- 不能作为长期产品实现。

根因不是 `tmux` 慢，而是外层宿主为了显示和交互引入了额外渲染成本。

## 2. 已有实验结论

### 2.1 外层 TUI 路线的价值

外层 TUI 路线帮助我们验证了这些产品判断：

- 左栏固定导航是合理的
- Workspace 应该独立于终端 pane/window 的概念
- 用户真正要的是“右侧像原生 tmux 一样工作”，而不是看一个终端镜像

### 2.2 外层 TUI 路线的上限

性能量化结果表明：

- 直接 `PTY + tmux attach-session` 路径，输入到结果可见大约 `0.20s`
- 外层整屏彩色重绘单帧大约 `18ms`

这意味着：

- 右侧一旦不是原生 tmux，而是“外层程序渲染 tmux 内容”，
- 就会持续为每次输入、滚动、刷新支付额外开销。

因此继续打磨外层宿主，不再符合目标优先级。

## 3. 为什么不是直接复用 choose-tree

直觉上，tmux 的 session/tree 选择界面已经很接近 sidebar。但源码研究表明这条路并不简单。

### 3.1 choose-tree 的真实定位

`choose-tree` 不是一个独立 sidebar 组件，而是：

- 通过 `cmd-choose-tree.c` 的 `cmd_choose_tree_exec()`
- 调用 `window_pane_set_mode(...)`
- 把目标 pane 切换到 `window_tree_mode`

然后 `window-tree.c` 会：

- 调用 `mode_tree_start(...)`
- 在这个 pane 内创建 tree-mode 的屏幕和交互

所以 choose-tree 的本质是：

- 一个 pane 内的模态 tree view
- 不是 client 级别的固定边栏

### 3.2 mode-tree 的价值

虽然 choose-tree 不能直接拿来当 sidebar，但 `mode-tree.c` 仍然很有价值。

它已经提供了成熟的：

- 树形数据结构
- 展开/折叠
- 搜索
- 过滤
- tag
- `j/k/g/G/h/l` 等交互语义

这说明我们**应该复用它的行为模型**，而不是重写 sidebar 的数据和交互。

## 4. 为什么需要改 tmux 的 client 层

### 4.1 重绘是 client 统一完成的

`screen-redraw.c` 的 `screen_redraw_screen()` 负责：

- panes
- borders
- status
- overlay

的统一绘制。

tmux 当前没有“左边固定 sidebar 区，右边正常绘制 panes”的原生概念。

要加常驻 sidebar，必须改：

- client 重绘上下文
- 可用终端区域划分
- sidebar 自己的绘制入口

### 4.2 输入也是 client 统一分发的

`server-client.c` 中的输入路径是：

1. overlay
2. prompt
3. key table
4. pane mode
5. `window_pane_key(...)`

这意味着一旦 sidebar 成为 client 固定区域，就必须在 client 层增加：

- sidebar 焦点
- sidebar 命中测试
- sidebar 鼠标单击/双击
- sidebar 键盘路由

而不是只在现有 pane mode 上做小修。

## 5. 可行路线对比

### 方案 A：fork tmux，新增原生 sidebar

优点：

- 右侧完全保留 tmux 原生体验
- 性能最接近理想目标
- window/pane/status bar 都无需再被外层程序模拟

缺点：

- 改动面大
- 需要长期维护 fork

### 方案 B：用 tmux control mode 做外部壳

优点：

- 不必深改 tmux 本体
- 外部可订阅 tmux 事件并渲染自己的左栏

缺点：

- 仍然不是 tmux 本体原生 sidebar
- 外部壳仍要承担一部分 UI/宿主复杂度

### 方案 C：继续外层 Textual/TUI 路线

结论：

- 已经验证不适合作为长期方案
- 不建议继续投入

## 6. 研究结论

如果目标是：

- 左栏常驻 workspace/session 导航
- 右栏完全保留原生 tmux
- 性能和交互优先

那么最正确的长期路线是：

- **fork tmux，增加原生 sidebar**

而不是继续在外层终端宿主上修修补补。

## 7. 下一步建议

下一次开发 thread 建议直接围绕 fork tmux 的最小可行版本推进：

1. 给 `client` 增加 sidebar 状态
2. 给 `screen-redraw` 增加 sidebar 固定绘制区域
3. 给 `server-client` 增加 sidebar 输入分发
4. 复用 `window-tree/mode-tree` 的数据与交互语义
5. 第一版先只做：
   - session/workspace 左栏
   - 右侧保留现有 tmux 原生显示
   - 鼠标单击预览/双击切换，或 `j/k + Enter`
