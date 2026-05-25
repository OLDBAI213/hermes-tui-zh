# TUI 汉化审查计划

## 当前状态

- 本地项目：`E:\AI\github\hermes-tui-zh`
- Hermes 源码：`E:\AI\hermes\hermes-agent`
- TUI 前端：`E:\AI\hermes\hermes-agent\ui-tui\src`
- TUI 后端：`E:\AI\hermes\hermes-agent\tui_gateway`
- 状态：P0 曾经做过一批主流程汉化，但需要重新按模块交叉验证。

## 模块分组

1. 基础壳：`entry.tsx`、`gatewayClient.ts`、`app.tsx`。
2. 主流程：`useMainApp.ts`、`turnController.ts`、`createGatewayEventHandler.ts`。
3. 输入：`useComposerState.ts`、`useInputHandlers.ts`、`textInput.tsx`。
4. 显示：`appLayout.tsx`、`appChrome.tsx`、`messageLine.tsx`、`thinking.tsx`。
5. slash：`app/slash/**`、`createSlashHandler.ts`。
6. 面板：`agentsOverlay.tsx`、session/model/prompt 相关组件。
7. 文案库：`content/zh.ts`、`content/verbs.ts`、`lib/text.ts`。
8. 后端事件：`tui_gateway/server.py`、`tui_gateway/event_publisher.py`。

## 交叉验证

- 正向：从用户场景出发，确认每个流程显示中文。
- 反向：从源码英文字符串出发，确认每个字符串的处理策略。
- 行为：用测试确认文案不是只改截图。
- 可视：用真实 TUI 确认布局不拥挤、不遮挡。

## 第一轮只做

- 建立英文字符串 inventory。
- 标出 P0/P1/P2。
- 补明显的 P0 漏项。
- 更新验证脚本，让以后漏项能被发现。

## 第一轮不做

- 不做新的布局美化。
- 不做发布安装包。
- 不改 dashboard 独立 UI。
- 不引入 i18n 新依赖。
