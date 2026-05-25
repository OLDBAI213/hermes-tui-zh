# 文件清单

这批改动已经应用到 `E:\AI\hermes\hermes-agent`。当前包含 P0 主流程汉化、P1 高频入口汉化和 P2 低频外壳补漏。

核心原则：

- 固定 UI 文案进 `ui-tui/src/content/zh.ts`。
- 用户输入、命令、路径、模型名、工具名不硬翻译。
- 后端原始异常只做前缀包装，不改异常内容。

文件：

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
- `ui-tui/dist/entry.js`（由 `npm run build` 生成）
