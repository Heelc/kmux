# kmux Example tmux Config Migration Design

## 1. Context

`kmux` 已经有原生 sidebar 和新的默认 workspace 快捷键语义，但项目内的
`example_tmux.conf` 仍然是旧的 tmux 示例配置，既没有体现 sidebar/workspace
的产品方向，也没有承接用户当前已经验证过的高频 tmux 使用方式。

用户当前本机 tmux 配置分成两层：

- oh-my-tmux 提供主题变量和大部分基线
- `~/.tmux.conf.local` 提供高频 `Option` 快捷键、视觉风格和少量行为覆盖

本轮目标不是把用户的个人配置原样搬进项目，而是把其中最稳定、最可分发的部分
迁移成 `kmux` 项目的示例配置。

## 2. Goals

- 用项目内示例配置体现 `kmux` 的 sidebar/workspace-first 方向
- 迁入用户最常用、最稳定的一组 `Option` 快捷键
- 提供一个不依赖 oh-my-tmux 的基础主题
- 保持示例配置可读、可维护，适合作为项目分发入口

## 3. Non-Goals

- 不原样复制 oh-my-tmux 变量体系
- 不迁入 TPM / 插件管理逻辑
- 不迁入强依赖用户本机环境的个性化设置
- 不在本轮实现完整高级主题系统
- 不在本轮设计额外 sidebar 新功能

## 4. File Layout

示例配置采用三层结构：

- `example_tmux.conf`
  - 入口文件
  - 只保留说明、少量通用基础项和两条 `source-file`
- `themes/kmux-base.conf`
  - 项目基础主题
  - 负责状态栏、pane border、消息样式、基础配色、sidebar 视觉基调
- `keybindings/kmux-keys.conf`
  - 项目默认快捷键
  - 负责高频 `Option` 快捷键和 sidebar/workspace 相关绑定

这样可以把“入口”“视觉”“快捷键”分开，后续再做美化增强时不会把单文件示例配置
继续堆乱。

## 5. Migration Scope

### 5.1 Migrate

本轮迁入以下内容：

- sidebar/workspace 相关快捷键
- 用户当前高频无前缀 `Option` 快捷键
- 基础主题能力：
  - status line 位置与样式
  - pane border 风格
  - message / mode 样式
  - 基础配色
  - 默认 `mouse on`
  - `default-terminal` / truecolor 类通用项

### 5.2 Do Not Migrate

本轮明确不迁：

- oh-my-tmux 的 `tmux_conf_theme_*` 变量体系
- 插件和 TPM 相关逻辑
- battery / urlscan / clipboard 等外围能力
- 明显属于个人环境的命令或展示项
- 和项目示例目的无关的冷门快捷键

## 6. Theme Direction

基础主题方向采用“冷静蓝灰”：

- 延续用户现有深色工作流的观感
- 使用稳定、克制的蓝灰配色，而不是极端个性化主题
- 让 sidebar 高亮、pane active border、状态栏当前段在同一视觉家族中

主题原则：

- 看起来像一个有主张的 `kmux`，而不是完全中性的 tmux 模板
- 但不要强到压过终端内容本身
- 不依赖 nerd-font 才能读懂配置
- 即便没有图标，状态栏也应清晰可用

## 7. Keybinding Design

### 7.1 Sidebar / Workspace

- `Option + s`
  - 进入 sidebar 焦点
  - 若已在 sidebar 焦点，则退出到右侧 pane
- `Option + Shift + s`
  - 保留原 session chooser
  - 对应 `choose-tree -s`

### 7.2 Session Management

- `Option + r`
  - rename session
- `Option + n`
  - new session
- `Option + x`
  - detach client

### 7.3 Window / Pane Management

迁入用户当前高频并且通用性高的组合：

- `Option + t`
  - new window in current path
- `Option + w`
  - kill pane
- `Option + f`
  - zoom pane
- `Option + ,`
  - rename window
- `Option + 1..9`
  - direct window select
- `Option + [ / ]`
  - previous / next window
- `Option + d`
  - horizontal split in current path
- `Option + Shift + d`
  - vertical split in current path

### 7.4 Deliberately Excluded

以下项本轮不进项目示例：

- `Option + Arrow` pane navigation
  - 这组在不同终端里最容易与宿主快捷键冲突
  - 用户本机已经专门为 Kitty 做过解除/重绑
  - 作为项目默认示例不够稳妥

## 8. Example Config Behavior

`example_tmux.conf` 最终应表现为：

- 用户 source 这一个入口文件，就能得到：
  - 基础主题
  - 默认 sidebar/workspace 快捷键
  - 一组高频 `Option` 快捷键
- 不需要依赖 oh-my-tmux 才能工作
- 不会自动创建默认 session/window 示例内容
- 不再保留当前示例文件里的过时演示逻辑，例如自动开 `irssi` / `mutt`

## 9. Compatibility Notes

- 项目内建默认绑定仍保留在 `key-bindings.c`
- 示例配置中的绑定允许覆盖 tmux 默认行为，用来体现 `kmux` 推荐工作流
- 若用户已有自己的 `.tmux.conf`，应允许只挑选 `themes/` 或 `keybindings/`
  中的单独文件 source

## 10. Validation

迁移完成后至少验证：

- `example_tmux.conf` 可以被 tmux 正常 source
- `themes/kmux-base.conf` 单独 source 不报错
- `keybindings/kmux-keys.conf` 单独 source 不报错
- `Option + s` / `Option + Shift + s` 行为符合 sidebar 设计
- 常见 `Option` 快捷键可在 clean config 下工作
- status line、pane border、message 样式符合基础主题预期

## 11. Deferred Work

后续可单独扩展：

- 更完整的 kmux 主题系统
- sidebar 专属样式变量
- agent 状态位的视觉设计
- terminal-host 适配更细的快捷键分层
- 面向不同终端（Kitty / iTerm2 / WezTerm）的可选键位预设
