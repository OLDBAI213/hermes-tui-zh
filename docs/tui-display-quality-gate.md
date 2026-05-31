# TUI 显示质量门

日期：2026-05-30

## 目标

把截图反馈里反复出现的问题收成固定质量门，避免“看到一处补一处”。

## 覆盖范围

- 工具调用：常见工具必须显示为 `emoji + 中文工具名 + 中文动作`，不能回退成 `Cronjob("list")` 这类函数形态；浏览器、终端、搜索这类高噪声上下文必须带动作提示，例如 `打开 ...`、`命令 ...`、`关键词 ...`。
- 工具失败：失败工具的详情必须明确显示 `失败原因：...`，当前轮次概览也要保留失败目标和原因。
- 思考显示：TUI 本机配置保持 `display.show_reasoning: true`、`display.sections.thinking: expanded`；如果配置被关，启动健康检查必须给中文提醒。
- 英文 reasoning：供应商返回英文 `reasoning_content` 时，TUI 只显示中文摘要，不直接暴露英文思考原文。
- 模型进度：等待模型、长等待心跳、响应完成要进入 `模型：...` 工具轨迹，并替换旧占位，不能让主界面像卡住。
- 当前轮次：TUI 忙碌时必须能看到当前阶段，例如等待模型、工具调用中、正在分析工具输出、工具失败，并显示工具完成/失败计数；失败时不能只显示泛化工具名。
- 启动流畅度：`gateway.ready` 必须先发出，MCP/外部工具发现不能阻塞 TUI 首屏；后台发现完成后必须刷新已就绪会话的工具面，agent 仍在初始化时要标记待刷新。
- 平台隔离：`status.update(kind=model)` 是 TUI 专用进度，不允许变成 Feishu、Telegram、Discord 等聊天平台里的连续气泡。
- 配置护栏：顶层 `display.show_reasoning` 和 `display.sections.thinking/tools` 必须让 TUI 可见；平台覆盖项可以单独关闭 Feishu reasoning。
- 旧构建：当前窗口启动后如果 `dist/entry.js` 被重新构建，TUI 必须提示重启窗口加载新构建。
- 交互验证：Windows ConPTY 验证器必须能真实提交 slash 命令；slash 自动输入要用尾随空格避开补全菜单吞 Enter。
- 验收隔离：长流程 TUI 验收默认必须使用独立 `HERMES_HOME` 和独立工作目录，不能写入真实用户会话；只有诊断时才允许显式 `--use-real-hermes-home`。
- 图片链路：主模型支持原生多模态时，TUI 附图和用户附图必须直接进入主模型，不能再暴露/调用外部 `vision_analyze`；只有显式 `agent.image_input_mode: text`、非视觉模型或 provider 真实拒绝工具结果图片时，才允许降级为文本摘要。
- 可见英文总账：TUI 运行源码里的用户可见英文必须经过 AST 审计；未批准英文为 0 才能算当前扫描范围内汉化完整。允许保留的英文只限产品名、API/协议名、键位、命令、路径、模型 id、转义序列等，并必须写入 allowlist 且带原因。

## 固定检查

- 前端集中契约：`ui-tui/src/__tests__/tuiDisplayContract.test.ts`
- 前端事件/运行态：`ui-tui/src/__tests__/createGatewayEventHandler.test.ts`、`ui-tui/src/__tests__/runtimeFreshness.test.ts`
- 后端显示契约：`tests/test_tui_display_contract.py`
- 后端启动链路：`tests/tui_gateway/test_entry_startup.py`、`tests/test_tui_gateway_server.py::test_refresh_mcp_tools_refreshes_ready_sessions`
- 后端平台隔离：`tests/agent/test_status_events.py`、`tests/gateway/test_feishu_zh_progress.py::test_gateway_model_status_is_tui_only_not_platform_message`
- 本地静态验收：`E:\AI\github\hermes-tui-zh\verify.ps1`
- 可见英文审计：`E:\AI\github\hermes-tui-zh\scripts\audit-visible-text.mjs` + `E:\AI\github\hermes-tui-zh\allowlist\tui-visible-english.json`
- 真实交互验收：`E:\AI\github\hermes-tui-zh\scripts\tui-long-run-acceptance.py`
- MiMo 图片回归：`tests/agent/test_image_routing.py`、`tests/test_model_tools.py::TestNativeVisionToolFiltering`、`tests/tools/test_vision_tools.py::TestVisionRequirements`、`tests/run_agent/test_multimodal_tool_content_recovery.py`、`tests/test_tui_gateway_server.py::test_tui_does_not_force_text_mode_for_xiaomi_mimo`

## 当前通过命令

- `npm run test --prefix ui-tui -- src/__tests__/tuiDisplayContract.test.ts src/__tests__/createGatewayEventHandler.test.ts src/__tests__/runtimeFreshness.test.ts src/__tests__/text.test.ts`
- `uv run pytest tests/agent/test_status_events.py tests/gateway/test_feishu_zh_progress.py::test_gateway_model_status_is_tui_only_not_platform_message -q -n0 --timeout-method=thread`
- `uv run pytest tests/test_tui_display_contract.py tests/test_tui_gateway_server.py::test_tui_startup_warnings_are_localized -q -n0 --timeout-method=thread`
- `uv run pytest tests/tui_gateway/test_entry_startup.py tests/test_tui_gateway_server.py::test_refresh_mcp_tools_refreshes_ready_sessions tests/test_tui_gateway_server.py::test_refresh_mcp_tools_marks_building_sessions_pending -q -n0 --timeout-method=thread`
- `pwsh -ExecutionPolicy Bypass -File E:\AI\github\hermes-tui-zh\verify.ps1 -HermesRoot E:\AI\hermes\hermes-agent`
- `node E:\AI\github\hermes-tui-zh\scripts\audit-visible-text.mjs --hermes-root E:\AI\hermes\hermes-agent --report E:\AI\github\hermes-tui-zh\tests\visible-text-report.md`
- `uv run --extra pty python scripts\tui_smoke_winpty.py --timeout 45 --marker "就绪" --before-input-delay 2 --slash-command "/status" --after-input-marker "Hermes TUI 状态" --forbid-marker "GatewayContext missing" --forbid-marker "not TTY" --forbid-marker "maximum update depth"`
- `uv run --extra pty python E:\AI\github\hermes-tui-zh\scripts\tui-long-run-acceptance.py`
- `uv run pytest tests\agent\test_image_routing.py tests\test_model_tools.py::TestNativeVisionToolFiltering tests\tools\test_vision_tools.py::TestVisionRequirements tests\run_agent\test_multimodal_tool_content_recovery.py tests\test_tui_gateway_server.py::test_tui_native_image_parts_use_xiaomi_nested_shape tests\test_tui_gateway_server.py::test_tui_does_not_force_text_mode_for_xiaomi_mimo -q -n0 --timeout-method=thread`

## 2026-05-30 审计结果

- `audit-visible-text.mjs` 扫描 `ui-tui/src/app`、`src/components`、`src/content`、`src/domain`、`src/lib`、`src/hooks` 的可见文案上下文。
- 本轮从 248 个未批准可见英文收敛到 0；报告：`E:\AI\github\hermes-tui-zh\tests\visible-text-report.md`。
- `verify.ps1` 已把该审计接成硬门：`TUI visible English audit passed`。

## 2026-05-30 长流程和 MiMo 图片回归

- 隔离长流程验收通过：`E:\AI\github\hermes-tui-zh\tests\long-run-acceptance\2026-05-30-isolated-check\long-run-acceptance.md`。
- 报告中 `隔离环境：是`，并记录独立 `HERMES_HOME` 与工作目录。
- MiMo 图片链路已加回归：`mimo-v2.5` 这类原生视觉主模型直接接收图片；`vision_analyze` 不再因为旧外部视觉 Key 出现在原生多模态工具面；工具结果图片仍保留“provider 真实拒绝后降级”的回退。
- 进程复查未发现 `tui-long-run-acceptance.py` 残留。
