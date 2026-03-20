# kmux 原生 Sidebar 规划

## 目标

- 把本轮关于“fork tmux 实现原生左侧 workspace/session sidebar”的研究背景和产品需求落到 `kmux` 仓库。
- 为下一次开发 thread 提供可直接接手的上下文，而不是再次从 `x-workspace` 的实验路线回溯。

## 当前阶段

- [x] 定位 `kmux` 仓库并确认当前分支/remote 状态
- [x] 建立项目内 planning 文件
- [x] 输出研究背景文档
- [x] 输出 PRD 文档
- [x] 复查文档结构与要点完整性
- [x] 本地提交文档变更
- [x] 初始化 `bd` 并创建 native sidebar 主线 issue
- [x] 更新 `AGENTS.md`，明确下个 agent 的 `bd` 工作流入口

## 关键决策

- 不再把当前 `x-workspace` 的 `Textual + Rich` 右侧终端宿主当作长期方案。
- `kmux` 的目标应以 “左侧常驻导航 + 右侧原生 tmux” 为主，不额外引入会显著影响性能的外层终端渲染宿主。
- 第一版优先做原生性能和交互正确性，美观和 AI agent 提示后置。

## 待交付文件

- `docs/native-sidebar-research.md`
- `docs/native-sidebar-prd.md`
- `findings.md`
- `progress.md`

## 风险

- `choose-tree` 并不是现成 sidebar 组件，不能低估改造成本。
- 要做到左栏常驻，必须改 `client` 重绘和输入分发，而不是只加一个 command。
- fork tmux 会带来长期维护成本，需要在 PRD 中明确“最小可行改动面”。
