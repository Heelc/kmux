# kmux Native Sidebar MVP Design

## 1. Context

`kmux` 的目标不是把 `choose-tree` 常驻化，而是在 tmux 本体内增加一个 client 级固定左侧 sidebar，使右侧继续保持原生 tmux 体验。

本设计文档基于以下已经确认的前提：

- `Workspace = session`
- MVP 只做 session 一层导航，不展开 window/pane
- sidebar 是 client 级 UI 区域，不是 pane mode
- 右侧 tmux 操作流和用户现有 key binding 必须继续工作

## 2. Goals

- 提供左侧常驻 session sidebar
- 右侧保留 tmux 原生 pane/window/status bar/鼠标/prefix 行为
- 支持键盘和鼠标导航
- 不引入持续性的外层渲染开销
- 保持后续扩展 agent 状态标记的空间

## 3. Non-Goals

- 不在 MVP 中展开 window/pane 树
- 不在 MVP 中接入搜索、过滤、tag、preview
- 不在 MVP 中设计默认快捷键
- 不在 MVP 中显示 agent 任务完成信息
- 不在 MVP 中做拖拽、自适应宽度、复杂卡片式信息
- 不在 MVP 中重构 `mode-tree` 为通用 client 组件

## 4. User Experience

### 4.1 Visible Model

- 左侧 sidebar 常驻显示在 client 左侧
- 右侧保持现有 tmux client 视图
- 左右之间有明确分隔线
- 分隔线样式尽量复用 tmux 现有 border 风格

### 4.2 Row Content

每个 session 条目单行显示：

- session 名
- 当前 session 标记
- 当前高亮样式
- 可选 attached 标记

后续在行右侧预留状态标记位，用于扩展 agent 完成态，但不进入 MVP 交付。

### 4.3 Focus Model

sidebar 不是全局键盘接管区，而是一个显式进入的导航态：

- 用户通过 `focus-sidebar` 命令进入 sidebar 焦点
- 用户鼠标点击左栏时，也可获得 sidebar 焦点
- 焦点进入后，只截获少量 sidebar 专用键
- 其余 tmux 键流，包括 prefix 和用户自定义绑定，继续按原生 tmux 流程处理

### 4.4 Selection Model

sidebar 中维护两套语义：

- `current`: 当前 client 正在附着的 session
- `selected`: sidebar 浏览态当前高亮的 session

规则如下：

- 不在 sidebar 焦点时，`selected` 应回到 `current`
- 进入 sidebar 焦点后，允许 `selected` 与 `current` 分离
- `Enter` 提交 `selected`
- `Esc` 取消浏览，丢弃未提交选择
- 关闭 sidebar 不提交选择

### 4.5 Keyboard Semantics

sidebar 焦点下：

- `j/k`：移动高亮
- `g/G`：跳到顶部/底部
- `Enter`：切换到高亮 session，并将焦点回到右侧 tmux
- `Esc`：退出 sidebar 焦点，不切换 session

不在 MVP 中处理：

- `/` 搜索
- 过滤
- tag
- 多键序列

### 4.6 Mouse Semantics

- 左栏单击：高亮条目并获得 sidebar 焦点
- 左栏双击：切换到对应 session，并回到右侧 tmux
- 左栏滚轮：滚动 sidebar 列表，不透传右侧 pane
- 右侧鼠标：继续由 tmux 原生路径处理

## 5. State Model

### 5.1 Session Default + Client Override

sidebar 可见性采用双层模型：

- `session` 提供默认值
- `client` 提供运行时 override

client attach 时：

1. 先读取 session 默认值
2. 再应用 client override

临时切换和持久默认值分离：

- `toggle-sidebar` 只修改当前 client 运行时状态
- `set-sidebar-default` 才写 session 或 global session option

### 5.2 Runtime State in `struct client`

建议在 `struct client` 中增加嵌套结构，例如：

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

设计原则：

- 使用嵌套小结构，不平铺一组零散字段
- `selected_session_id` 存 session id，不存列表索引
- client override 是运行时状态，不进入 option 系统

### 5.3 Width Model

sidebar 使用稳定列宽，不使用持续比例联动，也不按内容动态抖动。

MVP 数值约束：

- `default = 24`
- `min = 20`
- `max = 32`
- `pane_min = 20`

含义：

- sidebar 首选固定列宽
- resize 时优先压缩 sidebar，保住右侧 pane 的最低可用宽度
- 不自动隐藏 sidebar

## 6. Configuration Model

### 6.1 Persistent Options

持久默认值进入 session option 体系：

- 支持当前 session 设置
- 支持 `-g` 修改 global session 默认值

这与 tmux 原生 `set-option` 心智保持一致。

### 6.2 Runtime-Only State

以下状态不进入 option 表：

- 当前 client 是否临时 override
- 当前 client override 目标值
- 当前 client 是否在 sidebar 焦点
- 当前 client 当前选中条目

这些都属于 attach 生命周期内的 runtime client state。

## 7. Command Surface

MVP 只提供最小命令集合：

- `focus-sidebar`
- `toggle-sidebar`
- `set-sidebar-default`

设计原则：

- 必须走标准 tmux command/binding 机制
- 必须能被 `bind-key` 调用
- 不做只能从内部调用的私有入口
- 默认快捷键后续单独设计，不并入当前 MVP

## 8. Rendering Architecture

### 8.1 Entry Point

左栏绘制必须从 `screen_redraw_screen()` 进入，因为它是 client 全屏 redraw 总入口。

不采用“把 pane mode 画面嵌入左栏”的路线。

### 8.2 Module Boundary

第一版建议引入独立 sidebar 模块，而不是继续膨胀 `screen-redraw.c`。

建议边界：

- `sidebar.c` / `sidebar.h`
  - sidebar 宽度计算
  - 当前 session 列表遍历
  - 条目绘制
  - 命中测试
- `screen-redraw.c`
  - 负责调用 sidebar 绘制入口
  - 调整右侧可用绘制区域

### 8.3 Data Flow

第一版不维护长期缓存列表。

每次 redraw 或需要命中判断时，根据当前 sessions 现算 session 列表即可，因为：

- MVP 只有 session 一层
- 数据量小
- 提前引入缓存会增加失效同步复杂度

## 9. Input Routing

### 9.1 Primary Rule

sidebar 焦点不是新的全局 key table，只是一个窄白名单分支。

当 sidebar 焦点激活时：

- 白名单键交给 sidebar
- 其余一律沿用 tmux 原有按键流

白名单键：

- `j/k`
- `g/G`
- `Enter`
- `Esc`

鼠标按命中区域处理。

### 9.2 Current Client Switching

`Enter` 提交时，本质上相当于对当前 client 执行一次 session 切换：

- 只影响当前 client
- 不影响其他 client
- 切换后 `current` 与 `selected` 同步到新 session
- 焦点回右侧 pane

### 9.3 Cancel Semantics

- `Esc`：取消 sidebar 浏览，不切 session
- 隐藏 sidebar：只收起 UI，不切 session

## 10. Reuse Boundary for `mode-tree` / `window-tree`

MVP 不做 “把 `mode-tree` 抽成通用 client 侧组件” 的重构。

第一版复用边界是：

- 复用其成熟的导航语义思路
- 借鉴其排序/遍历/selection 模型
- 必要时借用局部 session 遍历或排序逻辑

第一版不复用：

- pane mode 生命周期
- preview
- popup/menu/help 流程
- pane 内 tree screen 绘制
- 完整 session/window/pane 树 UI

这是 `kmux-jl1` 的正确收敛边界：复用语义和可借用逻辑，不做大抽象。

## 11. Implementation Mapping

### Phase 1: Client State and Config (`kmux-0c3`)

- 在 `tmux.h` 为 `struct client` 增加 `client_sidebar_state`
- 在 `options-table.c` 增加 session option
- 增加读取 session 默认值和 client override 的初始化逻辑
- 增加最小命令面：
  - `focus-sidebar`
  - `toggle-sidebar`
  - `set-sidebar-default`

### Phase 2: Rendering (`kmux-e5d`)

- 引入 sidebar 独立绘制模块
- 在 `screen_redraw_screen()` 中先切出左侧 sidebar 区域
- 调整右侧 pane/redraw 上下文的可用区域
- 绘制：
  - session 列表
  - current 标记
  - selected 样式
  - 分隔线

### Phase 3: Input Routing (`kmux-cr0`)

- 在 client 输入路径中接入 sidebar 焦点判定
- 实现键盘白名单拦截
- 实现鼠标命中左栏的单击/双击/滚轮行为
- 保证 prefix 和自定义 tmux key binding 继续有效

### Phase 4: Reuse Refinement (`kmux-jl1`)

- 对齐 sidebar 的 selection/current 语义与 `mode-tree` 习惯
- 复用或抽出可借用的 session 排序/遍历逻辑
- 为后续搜索/过滤扩展预留接口，但不在 MVP 中交付

## 12. Validation Strategy

### 12.1 Functional Validation

- sidebar 始终显示在左侧
- `focus-sidebar` 能进入左栏焦点
- `j/k/g/G/Enter/Esc` 行为符合设计
- 单击/双击/滚轮行为符合设计
- `Enter` 只切当前 client
- 隐藏 sidebar 不提交未确认选择

### 12.2 Compatibility Validation

- prefix 行为不回归
- 用户已有 `bind-key` 绑定不回归
- 右侧 pane/window/status bar 行为不回归
- resize 后 sidebar/pane 宽度裁剪符合规则
- 多 client attach 同一 session 时，client override 互不污染

### 12.3 Regression Focus

重点观察：

- `screen_redraw_screen()` 改动是否破坏现有 pane/status/overlay redraw
- 输入路由改动是否打断原有 tmux key dispatch
- 极窄终端下 sidebar 压缩逻辑是否稳定

## 13. Risks

- client 级 sidebar 是 tmux 当前没有的原生概念，redraw 和 input 都会碰核心路径
- 如果过早追求 `mode-tree` 深复用，会把 MVP 变成大重构
- 如果 sidebar 键路由设计过宽，会破坏用户已有 tmux 绑定
- 如果宽度策略变成动态比例联动，会导致右侧 pane 区不断跳变

## 14. Deferred Work

后续版本可继续扩展：

- 搜索/过滤
- session 分组
- `window/pane` 树展开
- agent 任务完成状态标记
- 默认快捷键设计
- 更丰富的样式和计数信息
