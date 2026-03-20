# Task Plan

## Goal
对 `/Users/KaiHe/workspace/ai_prj/kmux/.worktrees/sidebar-mvp-impl` 当前未提交的 native sidebar MVP 改动做一次仅基于工作区产物的生产就绪性 code review，不修改代码。

## Constraints
- 仅审查未提交改动，不依赖主线程上下文。
- 输出 strengths、issues、recommendations、assessment。
- 每条问题给出文件和行号。
- 只报告真实问题；若无阻塞项需明确说明残余风险/测试缺口。

## Phases
- [in_progress] 收集范围：确认 diff、重点文件、测试脚本与实际工作树是否一致。
- [pending] 实现审查：逐文件检查状态、选项、命令、redraw、键盘与鼠标路由。
- [pending] 测试审查：读取相关回归脚本，评估覆盖和缺口。
- [pending] 结论输出：按严重性整理问题与合并建议。

## Errors Encountered
- 暂无。
