# kmux 原生 Sidebar PRD

## 1. 产品目标

为 `kmux` 增加一个**原生左侧 sidebar**，满足以下目标：

- 左侧常驻显示 workspace/session 列表
- 右侧保持原生 tmux 终端体验
- 不引入明显的额外性能损耗
- 支持鼠标操作和 vim 风格快捷键

## 2. 用户问题

现有 tmux 的 session 管理方式主要是：

- `choose-tree`
- `choose-client`
- `switch-client`
- 状态栏 window list

这些能力虽然强，但都不满足下面这个场景：

- 用户希望像 IDE 一样始终看到左侧工作区列表
- 用户在左侧浏览和切换 workspace/session
- 右侧继续直接使用原生 tmux 的 window、pane、status bar

## 3. 产品原则

### 3.1 原生体验优先

右侧必须尽量保持 tmux 原生行为：

- 终端性能
- prefix 行为
- 鼠标
- 颜色
- 滚动
- status bar

### 3.2 左栏只做导航

左栏不重复造右侧已经有的东西。  
它只负责：

- workspace/session 列表
- 当前项高亮
- attention/标记
- 搜索/过滤
- 切换入口

### 3.3 最小改动先落地

第一版不要一开始就做：

- AI agent attention
- 复杂动画
- 多层预览
- 自定义右侧 detail 面板

第一版先做“正确的框架”，再扩展能力。

## 4. 术语定义

- `Workspace`
  - 第一版直接等价为 tmux `session`
- `Terminal`
  - 等价为 tmux `window`
- `Split`
  - 等价为 tmux `pane`
- `Sidebar`
  - client 级固定左侧导航区域

## 5. 用户故事

### 5.1 浏览 workspace

作为用户，
我希望始终在左侧看到 workspace 列表，
这样我不必通过模态 chooser 才能知道当前有哪些 session。

### 5.2 键盘切换

作为用户，
我希望用 `j/k` 浏览 workspace，用 `Enter` 进入，
这样操作符合 tmux/vim 心智。

### 5.3 鼠标切换

作为用户，
我希望可以直接鼠标点击左栏条目，
这样在多 workspace 间切换时更直观。

### 5.4 右侧保持原生 tmux

作为用户，
我希望右侧仍然就是 tmux 本体，
这样我可以继续使用：

- tmux prefix
- window/pane 操作
- tmux status bar
- 原生性能

## 6. 第一版范围（MVP）

### 6.1 包含

- 左侧常驻 sidebar
- 左侧展示 session/workspace 列表
- 当前 workspace 高亮
- 键盘导航：
  - `j/k`
  - `g/G`
  - `Enter`
- 鼠标导航：
  - 单击高亮
  - 双击切换
- 右侧保持现有 tmux client/pane 视图
- 切换 workspace 时，右侧切到对应 session

### 6.2 不包含

- AI agent pane 级 attention
- 工作区内自定义卡片/概览
- 替换 tmux status bar
- workspace 级预览面板
- 复杂拖拽排序

## 7. 交互设计

### 7.1 键盘

- `j/k`：移动左栏高亮
- `g/G`：跳到顶部/底部
- `Enter`：切换到当前高亮 workspace
- `Ctrl-b` 等 tmux prefix：继续作用于右侧原生 tmux
- 焦点规则：
  - 第一版可以简化成“左栏在导航模式下吃键”
  - 确认进入后，右侧恢复 tmux 主输入

### 7.2 鼠标

- 左栏单击：高亮项
- 左栏双击：切换到对应 workspace
- 右侧鼠标：继续由 tmux 自己处理

## 8. 技术方案

### 8.1 需要修改的核心模块

- `tmux.h`
  - 给 `struct client` 增加 sidebar 状态
- `screen-redraw.c`
  - 增加 sidebar 固定绘制区域
  - 调整右侧 pane 的可绘制区域
- `server-client.c`
  - 增加 sidebar 焦点/键盘/鼠标路由
- `window-tree.c`
  - 复用 session/workspace tree 数据与默认命令语义
- `mode-tree.c`
  - 复用列表、过滤、搜索、tag 的行为模型

### 8.2 推荐实现方式

不是把 `choose-tree` 原样嵌入左栏，而是：

1. 复用 `window-tree/mode-tree` 的树数据和交互逻辑
2. 新增 client 级 sidebar 状态
3. 在 `screen-redraw` 里直接绘制 sidebar
4. 在 `server-client` 里处理 sidebar 焦点与事件

## 9. 最小可行版本的实现顺序

### Phase 1

- 定义 sidebar 数据结构
- 给 `client` 增加 sidebar 开关和当前选择状态

### Phase 2

- 让 `screen-redraw` 在左侧画出最小 session 列表
- 右侧仍保持原有 pane 绘制

### Phase 3

- 接通 `j/k + Enter`
- 接通鼠标单击/双击

### Phase 4

- 复用 `mode-tree/window-tree` 的过滤与搜索能力

## 10. 验收标准

第一版验收以“原生体验优先”为准：

- 左侧始终可见
- 右侧 tmux 体验与未改造前基本一致
- `Ctrl-b`、窗口切换、分屏、颜色、滚动都正常
- 左栏切换 session 不引入明显性能损耗
- `choose-tree` 不再是唯一 session 导航入口

## 11. 后续扩展

后续版本可继续加：

- attention 标记
- 最近使用 workspace
- agent 完成状态提示
- workspace 分组
- 更丰富的搜索/过滤

但这些都应建立在 **MVP 的原生 sidebar 已稳定** 的前提下。
