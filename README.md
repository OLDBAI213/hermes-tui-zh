# hermes-tui-zh

Hermes 原生 TUI 中文化项目。当前先做 P0 主流程汉化、P1 高频入口汉化、P2 低频外壳补漏，不改 TUI 布局，不做独立发行包。

## 当前完成

P0/P1/P2 已落到 Hermes 本体：

- 提交时会话未就绪、排队、错误、shell 响应异常。
- 忙碌时插入失败后的队列提示。
- 中断标记和中断系统消息。
- 工具结果为空、系统长消息折叠提示。
- 底部输入占位、后台任务提示。
- 剪贴板图片、语音、编辑器打开失败、通用 slash 错误包装。
- `/help`、`/status`、`/details`、`/copy`、`/history`、`/save`、`/queue`、`/steer`、`/undo`。
- `/model`、`/personality`、`/compress`、`/skin`、`/indicator`、`/reasoning`、`/fast`、`/busy`、`/verbose`。
- `/browser`、`/rollback`、`/agents`、`/replay`、`/skills`、`/tools`。
- 模型选择器、子 Agent 面板、终端快捷键提示。
- `/debug` 内存诊断输出、网关退出提示、模糊命令提示。
- `/fortune` 本地签文、长时间工具提示、terminal 工具动词、思考状态词。
- 首次设置/缺少 provider 的状态提示。
- 思考内容里旧英文状态词过滤，例如 `reflecting`、`cogitating`；表情状态前缀也会一起清掉，避免残留半截颜文字。
- 状态栏不再显示空闲语音状态 `语音 关`。
- 保持 `display.mouse_tracking: true`，让滚轮滚动对话区，而不是触发输入历史。
- 遮罩弹层补漏：sudo 密码提示、secret env 提示、分页帮助提示。
- 任务面板补漏：`Todo`、`incomplete/pending` 显示改为中文。
- 启动/恢复/运行/队列/中断状态源头改为中文，保留旧英文映射兼容。
- 网关协议噪声、命令目录不可用、语音连续模式停止、MCP 自动重载提示已汉化。
- `/skills`、`/tools` 的页面标题、空输出、列表/详情标题补充汉化。
- 子 Agent 内联委托分组兼容中文 `委托任务`。
- 测试预期已同步当前中文工具名、子任务汇总和 `重载技能` 标题。

## 代码位置

Hermes 源码：

`E:\AI\hermes\hermes-agent`

本次改动文件：

- `ui-tui/src/content/zh.ts`
- `ui-tui/src/domain/messages.ts`
- `ui-tui/src/lib/text.ts`
- `ui-tui/src/lib/subagentTree.ts`
- `ui-tui/src/lib/terminalSetup.ts`
- `ui-tui/src/lib/terminalParity.ts`
- `ui-tui/src/content/fortunes.ts`
- `ui-tui/src/content/charms.ts`
- `ui-tui/src/content/verbs.ts`
- `ui-tui/src/app/useSubmission.ts`
- `ui-tui/src/app/useSessionLifecycle.ts`
- `ui-tui/src/app/useConfigSync.ts`
- `ui-tui/src/app/uiStore.ts`
- `ui-tui/src/app/setupHandoff.ts`
- `ui-tui/src/app/turnController.ts`
- `ui-tui/src/app/useMainApp.ts`
- `ui-tui/src/app/useInputHandlers.ts`
- `ui-tui/src/app/createGatewayEventHandler.ts`
- `ui-tui/src/app/createSlashHandler.ts`
- `ui-tui/src/app/slash/commands/core.ts`
- `ui-tui/src/app/slash/commands/ops.ts`
- `ui-tui/src/app/slash/commands/session.ts`
- `ui-tui/src/app/slash/commands/debug.ts`
- `ui-tui/src/components/messageLine.tsx`
- `ui-tui/src/components/appLayout.tsx`
- `ui-tui/src/components/appOverlays.tsx`
- `ui-tui/src/components/appChrome.tsx`
- `ui-tui/src/components/todoPanel.tsx`
- `ui-tui/src/components/agentsOverlay.tsx`
- `ui-tui/src/components/modelPicker.tsx`
- `ui-tui/src/components/thinking.tsx`
- `ui-tui/src/__tests__/createGatewayEventHandler.test.ts`
- `ui-tui/src/__tests__/createSlashHandler.test.ts`
- `ui-tui/src/__tests__/text.test.ts`
- `ui-tui/src/__tests__/useInputHandlers.test.ts`
- `ui-tui/src/__tests__/messages.test.ts`
- `ui-tui/src/__tests__/reasoning.test.ts`
- `ui-tui/src/__tests__/subagentTree.test.ts`

## 验证

```powershell
pwsh -ExecutionPolicy Bypass -File .\verify.ps1
```

当前本机结果：

- `pwsh -ExecutionPolicy Bypass -File .\verify.ps1`: 通过，0 失败。
- `npm test -- src/__tests__/createGatewayEventHandler.test.ts src/__tests__/text.test.ts src/__tests__/useInputHandlers.test.ts`: 75 通过。
- `npm run type-check`: 通过。
- `npm run build`: 通过，已更新 TUI dist。
- `npm test -- src/__tests__/reasoning.test.ts src/__tests__/prompt.test.ts src/__tests__/slashParity.test.ts src/__tests__/createSlashHandler.test.ts`: 64 通过，3 跳过。
- 定向 eslint：0 错误，3 个既有 warning。
- Windows ConPTY smoke：通过，真实 TUI 从 `ui-tui/dist/entry.js` 启动，最新输出见 `tests/2026-05-25-p3-winpty-smoke-output.txt`。
- 隔离首次设置 smoke：通过，缺 provider 时显示中文“需要设置”。
- TUI 无牺牲完整基线：通过，报告见 `E:\AI\github\hermes-tui-reverse-study\tests\20260525-210539-no-regression-Full.txt`，`Failed: 0`。

## 后续

下一步：

- 先修交互验证器：现有 ConPTY 手工输入能写入命令，但没有可靠触发 Enter 提交。
- 真实 TUI 交互截图验收。
- 用户确认后再做布局/美化，避免和汉化混在一起。
