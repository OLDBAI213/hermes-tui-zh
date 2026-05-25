# 状态

日期：2026-05-25

## 当前状态

P0 主流程汉化 + P1 高频入口汉化 + P2 低频外壳补漏已直接落到 Hermes 原生 TUI 源码。2026-05-25 又补了思考状态词、首次设置状态、状态栏语音占位、滚轮配置、遮罩弹层、任务面板、启动/恢复/运行状态、协议噪声、命令目录、MCP 自动重载、语音连续模式停止、`/skills` 和 `/tools` 标题/空输出：`REASONING_STATUS_WORDS` 已从英文改为中文，历史 reasoning 里的 `reflecting`/`cogitating` 会过滤，表情状态前缀也会清掉，缺少 provider 时不再显示 `setup required`，空闲状态不再显示 `语音 关`，`display.mouse_tracking` 已恢复为 `true`，sudo/secret/pager 弹层提示已汉化，任务面板不再显示 `Todo` / `incomplete`。

当前不是正式发布包，先保证本机可用、可追踪、可继续。

## 已验证

- `pwsh -ExecutionPolicy Bypass -File E:\AI\github\hermes-tui-zh\verify.ps1`: 通过，0 失败，包含 P2 补漏规则。
- `npm test -- src/__tests__/createGatewayEventHandler.test.ts src/__tests__/text.test.ts src/__tests__/useInputHandlers.test.ts`: 75 通过，覆盖网关状态/协议提示、旧英文思考词过滤和滚轮/语音相关输入处理。
- `npm run type-check`: 通过，包括 2026-05-25 状态源头、思考状态词和语音占位补漏后复跑。
- `npm run build`: 通过，已更新 `ui-tui/dist/entry.js`。
- `npm test -- src/__tests__/reasoning.test.ts src/__tests__/prompt.test.ts src/__tests__/slashParity.test.ts src/__tests__/createSlashHandler.test.ts`: 64 通过，3 跳过。
- `npm test -- --run src/__tests__/messages.test.ts src/__tests__/reasoning.test.ts src/__tests__/subagentTree.test.ts`: 49 通过，覆盖中文工具名、思考表情状态清理、子任务汇总。
- `pwsh -ExecutionPolicy Bypass -File E:\AI\github\hermes-tui-reverse-study\tools\run-no-regression-baseline.ps1 -Mode Full -RunZhVerify`: 通过，报告 `E:\AI\github\hermes-tui-reverse-study\tests\20260525-210539-no-regression-Full.txt`，`Failed: 0`。
- 定向 eslint：0 错误，3 个既有 warning（`src/app/useMainApp.ts` hook/react-compiler 规则）。
- `uv run --extra pty python scripts\tui_smoke_winpty.py --timeout 35 --dump E:\AI\github\hermes-tui-zh\tests\2026-05-25-p3-winpty-smoke-output.txt`: 通过。
- 隔离 `HERMES_HOME` 首次设置冒烟：通过，输出见 `tests/2026-05-25-isolated-setup-zh-output.txt`，确认缺 provider 时显示“需要设置”，未出现 `setup required`。

Smoke 输出：

- `PASS: TUI started under Windows ConPTY.`
- 启动入口：`E:\AI\hermes\hermes-agent\ui-tui\dist\entry.js`

## 下一步

下一步不要重做布局：

1. 修正或新增交互验证器：现有 ConPTY 手工输入能把 `/mem` 写进输入框，但没有可靠触发 Enter，不能作为命令执行验收依据。
2. 真实 TUI 交互截图验收：`/help`、`/model`、`/agents`、`/browser`、`/skills`、`/mem`、`/fortune`。
3. 若用户确认视觉方向，再做布局/美化，不和汉化混在一起。
