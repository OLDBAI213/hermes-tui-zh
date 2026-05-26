# 状态

日期：2026-05-26

## 当前状态

P0 主流程汉化 + P1 高频入口汉化 + P2 低频外壳补漏已直接落到 Hermes 原生 TUI 源码。2026-05-25 又补了思考状态词、首次设置状态、状态栏语音占位、滚轮配置、遮罩弹层、任务面板、启动/恢复/运行状态、协议噪声、命令目录、MCP 自动重载、语音连续模式停止、`/skills` 和 `/tools` 标题/空输出：`REASONING_STATUS_WORDS` 已从英文改为中文，历史 reasoning 里的 `reflecting`/`cogitating` 会过滤，表情状态前缀也会清掉，缺少 provider 时不再显示 `setup required`，空闲状态不再显示 `语音 关`，`display.mouse_tracking` 已恢复为 `true`，sudo/secret/pager 弹层提示已汉化，任务面板不再显示 `Todo` / `incomplete`。

2026-05-26 补充：修复一轮回复已经显示后，后台记忆/待办等收尾工具还在运行时状态栏只显示随机“正在做”的问题。现在这类场景会显示“回答已生成，后台收尾…”，审批、等待输入、工具准备等明确状态也不会再被状态动画盖住。本机 `E:\AI\hermes\config.yaml` 已恢复 TUI 思考显示：`display.show_reasoning: true`，`display.sections.thinking: expanded`；飞书侧 `display.platforms.feishu.show_reasoning` 仍保持 `false`，没有误改飞书显示规则。

2026-05-26 晚间补充：重点排查“思考/思维链汉化一会有一会没有”。结论是三类来源混在一起：TUI 面板标题/状态词是前端文案，应该稳定中文；模型实时返回的 `reasoning` / `reasoning_content` 是供应商原文，会出现英文；历史会话里已经存下的英文 reasoning 也会被回放。最新会话样本 `session_20260526_150922_ed4651.json` 中 486 条 reasoning 字段里 328 条偏英文，证明问题主要来自模型原文和历史缓存，不是单个标题漏翻。已做的最小修正：TUI 自身的 `tokens` 显示改成“令牌”；英文 reasoning 不再假装已汉化，而是在思考区标记“模型返回英文思考，已按原文显示”；网关中文规则加强，明确要求可见 thinking/reasoning 不用 `Let me` / `I should` 等英文开头；TUI 本机配置保持 `show_reasoning: true` 和 `sections.thinking: expanded`。

2026-05-26 夜间补充：修复后台进程完成通知导致的 TUI 频闪。根因是 `terminal(background=true, notify_on_complete=true)` 的完成事件到达时，如果 TUI 会话仍在运行，网关会把同一个事件重新放回队列，但下一轮又立刻取出并发 `status.update`，造成同一条 `[IMPORTANT: Background process ...]` 在状态区反复刷新。现在忙碌时只回队列、不刷界面；空闲后才接管一次，并且 TUI 状态只显示短中文“后台进程完成：proc_xxx（退出码 n）”。完整 `[IMPORTANT...]` 仍保留为内部 agent 接续提示，不再直接污染 TUI 状态栏。

2026-05-26 深夜补充：修复飞书/TUI 后端生命周期状态漏英文。用户截图里的 `Model returned empty after tool calls — nudging to continue`、`Empty response from model — retrying (1/3)` 等不是前端标题漏翻，而是 `agent._emit_status()` 经网关 `status_callback` 直接发送到飞书；TUI 前端也只兜底了一条。现在飞书出口新增生命周期状态汉化，覆盖空响应恢复、重试、仅思考补写、切换备用模型、无效响应重试等；TUI 前端同批兜底；长运行提示里的 `API call #17 completed` 也会显示为“第 17 次模型调用完成”。这次没有改飞书正文布局、工具调用记录格式或消息显示规则。

同次清理：`gateway/run.py` 里早先重复插入的飞书状态分支和 `/resume` 飞书列表分支各有 14 份，后 13 份都是不可达重复代码；已压成单份，减少后续审查噪声。

2026-05-26 继续补漏：用真实 `feishu-outbound.ndjson` 反查后，补齐工具调用记录里的内部工具名：`skill_view`、`skill_manage`、`vision_analyze`、`cronjob`、`browser_cdp` 现在会显示为“查看技能 / 管理技能 / 视觉分析 / 定时任务 / 浏览器 CDP”，并保留对应 emoji。飞书和 TUI 的生命周期状态也扩展到上下文压缩、限流等待、无响应重连、无效响应重试、流式异常等高频故障文案，避免截图里那种英文状态反复出现。

同次修复飞书 `post` 随机失败：旧代码把富文本样式生成为 `{"bold": true}` 这种对象，飞书 `post` 实际需要 `["bold"]` 这类数组；删除线也应是 `lineThrough`。这会导致 `[230001] content format of the post type is incorrect`，随后退回纯文本。现在样式生成改为飞书原生格式，通配符 `*.ps1` / `*.md` 不再被误判为斜体，内联代码按普通文本发，优先保证 post 成功和显示顺序稳定。

同次修复 TUI 构建产物启动失败：Windows ConPTY 烟测发现 `ui-tui/dist/entry.js` 文件尾混入未注释许可证文本，导致 Node 报 `SyntaxError: Unexpected identifier 'file'`。根因是 esbuild EOF legal comment 聚合与 React 许可证块组合后产出坏 JS；构建脚本已改为 `legalComments: 'linked'`，许可证输出到 `entry.js.LEGAL.txt`，入口文件恢复可执行。

2026-05-26 继续交叉审查：发现图片链还有第二个英文源头。除了网关飞书图片预分析路径，`run_agent.py` 的 Anthropic 多模态降级路径也会注入 `The user attached an image... use vision_analyze with image_url...`，这会影响非原生视觉模型或降级路径，并可能让模型把内部工具说明说给用户。现在两条图片链都改为中文内部说明：自动识别提示、失败提示、继续细看提示都使用“视觉分析 工具，图片路径：...”，不再出现英文 `vision_analyze with image_url`。

同次统一测试口径：旧测试里仍保留 Feishu `post` 的旧样式对象期望，已全部改成飞书原生样式数组；并新增接收侧数组样式解析测试，确保收到 `["bold"]` / `["italic"]` / `["lineThrough"]` / `["underline"]` 时仍能正确还原为内部 Markdown 文本。

2026-05-26 继续补漏：按“不是只查已改内容”的方式反向搜模型/飞书可见提示，补齐语音、音频附件、文档附件、回复引用、频道回填和贴纸描述的中文化。现在语音转写失败、未配置 STT、音频文件路径提示、文档路径提示、`reply_to` 引用、`[New message]` 回填标记、贴纸/动态贴纸说明都会以中文发给模型/飞书；贴纸视觉描述 prompt 也改为要求中文，避免贴纸内容描述本身继续产出英文。

同次继续扩大到通用网关命令：Discord 语音频道的失败/加入/离开提示、Telegram topic 多会话模式的主说明、帮助、关闭、恢复、未绑定会话列表等直接返回给用户的正文改为中文。顺手修复一个真实跨上下文路由问题：Telegram topic 绑定按 `updated_at` 排序在同一秒写入时不稳定，未知 thread_id 可能回到旧 topic；现在排序增加 `linked_at` 和 `rowid` 兜底，保证最后写入的绑定排前面。

TUI 侧继续补漏：网关重启、未连接、WebSocket 关闭、请求超时、未知错误等底层 transport 错误过去会以英文拼进“错误: ...”或弹层错误里。现在 `rpcErrorMessage` 统一做中文归一化，`gateway.error` 事件也显示“错误: 中文原因”，不会再把 `gateway not running`、`request failed`、`unknown error` 这类英文直接露给用户。

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
- 2026-05-26 状态栏/思考修复后验证：
  - `npx eslint src/app/createGatewayEventHandler.ts src/components/appChrome.tsx src/lib/text.ts src/__tests__/statusBarTicker.test.ts src/__tests__/createGatewayEventHandler.test.ts`: 通过，0 错误。
  - `npm run type-check --prefix ui-tui`: 通过。
  - `npm run test --prefix ui-tui -- src/__tests__/statusBarTicker.test.ts src/__tests__/createGatewayEventHandler.test.ts`: 46 通过。
  - `npm run build --prefix ui-tui`: 通过，已更新 `ui-tui/dist/entry.js`。
  - `uv run --extra pty python scripts\tui_smoke_winpty.py --timeout 25 --marker Hermes --forbid-marker "GatewayContext missing" --forbid-marker "not TTY"`: 通过。
- 2026-05-26 交叉验证：
  - 配置反查：`display.show_reasoning=true`，`display.sections.thinking=expanded`，`display.platforms.feishu.show_reasoning=false`。
  - 构建产物反查：`ui-tui/dist/entry.js` 已包含“回答已生成，后台收尾…”、`POST_RESPONSE_TOOLS` 和 `explicitBusyStatusLabel`。
  - 当前 TUI 进程反查：运行入口为 `E:\AI\hermes\hermes-agent\ui-tui\dist\entry.js`，创建时间晚于本次构建。
  - 更大相关测试：`npm run test --prefix ui-tui -- src/__tests__/statusBarTicker.test.ts src/__tests__/createGatewayEventHandler.test.ts src/__tests__/useConfigSync.test.ts src/__tests__/text.test.ts src/__tests__/reasoning.test.ts src/__tests__/slashParity.test.ts`：113 通过，3 跳过。
  - 网关协议回归：`uv run pytest tests/test_tui_gateway_server.py tests/tui_gateway/test_protocol.py -q -n0 --timeout-method=thread`：242 通过。
  - 日志抽查：未发现新的 `GatewayContext missing`、`not TTY`、`maximum update depth`、TUI 崩溃；日志中仍有浏览器/CDP/Tavily/终端链路错误，属于后续浏览器自动化问题，不属于本次 TUI 状态栏修复。
- 2026-05-26 思考汉化不稳定排查后验证：
  - `npx eslint src/lib/text.ts src/components/thinking.tsx src/lib/subagentTree.ts src/domain/messages.ts src/components/agentsOverlay.tsx src/app/slash/commands/session.ts src/__tests__/text.test.ts src/__tests__/subagentTree.test.ts`：通过，0 错误。
  - `npm run type-check --prefix ui-tui`：通过。
  - `npm run test --prefix ui-tui -- src/__tests__/text.test.ts src/__tests__/subagentTree.test.ts`：63 通过。
  - `npm run test --prefix ui-tui -- src/__tests__/text.test.ts src/__tests__/subagentTree.test.ts src/__tests__/createGatewayEventHandler.test.ts src/__tests__/statusBarTicker.test.ts`：109 通过。
  - `uv run pytest tests/test_tui_gateway_server.py::test_sync_agent_system_prompt_requires_chinese_visible_reasoning tests/test_tui_gateway_server.py::test_config_set_reasoning_updates_live_session_and_agent -q -n0 --timeout-method=thread`：2 通过。
  - `uv run pytest tests/test_tui_gateway_server.py tests/tui_gateway/test_protocol.py -q -n0 --timeout-method=thread`：243 通过。
  - `npm run build --prefix ui-tui`：通过，`ui-tui\dist\entry.js` 更新时间 `2026-05-26 20:36:50`。
  - `uv run --extra pty python scripts/tui_smoke_winpty.py --timeout 25 --marker Hermes --forbid-marker "GatewayContext missing" --forbid-marker "not TTY" --forbid-marker "maximum update depth"`：通过。
  - 说明：`npm run lint --prefix ui-tui -- ...` 会执行脚本内置的全仓 `eslint src/ packages/`，仍会扫出仓库既有 lint 错误；本次使用上面的定向 `npx eslint` 作为改动判定。
- 2026-05-26 后台通知频闪修复后验证：
  - `uv run pytest tests/test_tui_gateway_server.py::test_notification_poller_delivers_completion tests/test_tui_gateway_server.py::test_notification_poller_requeues_when_busy tests/test_tui_gateway_server.py::test_config_set_reasoning_updates_live_session_and_agent tests/test_tui_gateway_server.py::test_sync_agent_system_prompt_requires_chinese_visible_reasoning -q -n0 --timeout-method=thread`：4 通过。
  - `npm run type-check --prefix ui-tui`：通过。
  - `npm run test --prefix ui-tui -- src/__tests__/text.test.ts src/__tests__/subagentTree.test.ts src/__tests__/createGatewayEventHandler.test.ts src/__tests__/statusBarTicker.test.ts`：109 通过。
  - `uv run pytest tests/test_tui_gateway_server.py tests/tui_gateway/test_protocol.py -q -n0 --timeout-method=thread`：243 通过。
  - `npm run build --prefix ui-tui`：通过，已更新 `ui-tui\dist\entry.js`。
  - 定向 eslint：通过，0 错误。
  - Windows ConPTY 冒烟：通过，未出现 `GatewayContext missing`、`not TTY`、`maximum update depth`。
  - 配置复查：`display.show_reasoning=true`，`display.sections.thinking=expanded`，`display.platforms.feishu.show_reasoning=false`。
- 2026-05-26 飞书/TUI 状态英文漏出修复后验证：
  - `uv run pytest tests/gateway/test_feishu_zh_progress.py -q -n0 --timeout-method=thread`：23 通过。
  - `uv run pytest tests/gateway/test_feishu_zh_progress.py tests/gateway/test_telegram_noise_filter.py -q -n0 --timeout-method=thread`：29 通过。
  - `npm run test --prefix ui-tui -- src/__tests__/createGatewayEventHandler.test.ts`：43 通过。
  - `npx eslint ui-tui/src/app/createGatewayEventHandler.ts ui-tui/src/__tests__/createGatewayEventHandler.test.ts`：通过，0 错误。
  - `npm run type-check --prefix ui-tui`：通过。
  - `npm run build --prefix ui-tui`：通过，已更新 `ui-tui\dist\entry.js`。
  - `uv run --extra pty python scripts\tui_smoke_winpty.py --timeout 25 --marker Hermes --forbid-marker "GatewayContext missing" --forbid-marker "not TTY" --forbid-marker "maximum update depth"`：通过。
  - `python -m py_compile gateway\run.py`：通过。
  - `git diff --check -- gateway/run.py tests/gateway/test_feishu_zh_progress.py tests/gateway/test_telegram_noise_filter.py ui-tui/src/app/createGatewayEventHandler.ts ui-tui/src/__tests__/createGatewayEventHandler.test.ts`：通过，只有 Windows 换行提示。
  - 反查重复块：`is_feishu_zh = (` 仅 1 处，`lines = ["📋 可恢复会话"]` 仅 1 处。
  - `hermes gateway restart`：已重启飞书网关，旧 PID `30096` 已停止，新 PID `29952` 运行；日志确认 `✓ feishu connected`。
- 2026-05-26 深夜补漏验证：
  - `uv run pytest tests/gateway/test_feishu_zh_progress.py tests/gateway/test_telegram_noise_filter.py tests/gateway/test_feishu.py::TestAdapterBehavior::test_build_post_payload_converts_markdown_to_native_elements tests/gateway/test_feishu.py::TestAdapterBehavior::test_build_post_payload_uses_feishu_native_style_arrays tests/gateway/test_feishu.py::TestAdapterBehavior::test_build_post_payload_does_not_treat_glob_asterisks_as_italic tests/gateway/test_feishu.py::TestAdapterBehavior::test_build_post_payload_strips_raw_markdown_markers tests/gateway/test_feishu.py::TestFeishuAdapterMessaging::test_markdown_post_polisher_does_not_rewrite_code_blocks -q -n0 --timeout-method=thread`：34 通过。
  - `npm run test --prefix ui-tui -- src/__tests__/createGatewayEventHandler.test.ts`：43 通过。
  - `npx eslint ui-tui/src/app/createGatewayEventHandler.ts ui-tui/src/__tests__/createGatewayEventHandler.test.ts`：通过，0 错误。
  - `npm run type-check --prefix ui-tui`：通过。
  - `npm run build --prefix ui-tui`：通过，已生成 `ui-tui\dist\entry.js` 和 `ui-tui\dist\entry.js.LEGAL.txt`。
  - `node --check ui-tui\scripts\build.mjs`：通过。
  - `python -m py_compile gateway\run.py gateway\platforms\feishu.py`：通过。
  - `uv run --extra pty python scripts\tui_smoke_winpty.py --timeout 25 --marker Hermes --forbid-marker "GatewayContext missing" --forbid-marker "not TTY" --forbid-marker "maximum update depth"`：通过。
  - `git diff --check -- gateway/run.py gateway/platforms/feishu.py tests/gateway/test_feishu_zh_progress.py tests/gateway/test_feishu.py ui-tui/src/app/createGatewayEventHandler.ts ui-tui/src/__tests__/createGatewayEventHandler.test.ts ui-tui/scripts/build.mjs`：通过，只有 Windows 换行提示。
  - 构建产物反查：`ui-tui\dist\entry.js` 只保留 `For license information please see entry.js.LEGAL.txt`，未再出现坏的 `Bundled license information` 残块。
  - 重复块反查：`is_feishu_zh = (` 仅 1 处，`lines = ["📋 可恢复会话"]` 仅 1 处。
  - `hermes gateway restart`：已重启飞书网关，旧 PID `29952` 已停止，新 PID `28372` 运行；日志确认 `✓ feishu connected`。
  - `hermes --version`：当前 `Hermes Agent v0.14.0 (2026.5.16)`；提示远端有更新。因当前工作树存在未提交的飞书/TUI修复，未直接执行 `hermes update`，避免把未打包成果卷入更新冲突。
- 2026-05-26 继续交叉审查验证：
  - `uv run pytest tests/gateway/test_feishu.py tests/gateway/test_feishu_zh_progress.py tests/gateway/test_vision_memory_leak.py tests/run_agent/test_run_agent.py::TestAnthropicImageFallback::test_build_api_kwargs_converts_multimodal_user_image_to_text -q -n0 --timeout-method=thread`：238 通过。
  - `python -m py_compile gateway\run.py gateway\platforms\feishu.py run_agent.py`：通过。
  - 源码反查：`The user attached an image`、`The user sent an image`、`vision_analyze with image_url`、`Image analysis failed` 只剩测试里的负向断言，不再是运行时代码。
  - `uv run --extra pty python scripts\tui_smoke_winpty.py --timeout 25 --marker Hermes --forbid-marker "GatewayContext missing" --forbid-marker "not TTY" --forbid-marker "maximum update depth"`：通过。
  - `hermes gateway restart`：已重启飞书网关，新 PID `5752` 运行；日志确认 `✓ feishu connected`，飞书收到“网关正在重启/网关已上线”提示。
- 2026-05-26 非文本消息中文补漏验证：
  - `uv run pytest tests/gateway/test_stt_config.py tests/gateway/test_telegram_audio_vs_voice.py tests/gateway/test_reply_to_injection.py tests/gateway/test_session.py::TestGatewayAttachmentContext -q -n0 --timeout-method=thread`：18 通过。
  - `uv run pytest tests/gateway/test_sticker_cache.py tests/gateway/test_session.py::TestSenderPrefixWithBackfill tests/gateway/test_session.py::TestGatewayAttachmentContext -q -n0 --timeout-method=thread`：22 通过。
  - `uv run pytest tests/gateway/test_feishu.py tests/gateway/test_feishu_zh_progress.py tests/gateway/test_vision_memory_leak.py tests/gateway/test_stt_config.py tests/gateway/test_telegram_audio_vs_voice.py tests/gateway/test_reply_to_injection.py tests/gateway/test_sticker_cache.py tests/gateway/test_session.py::TestSenderPrefixWithBackfill tests/gateway/test_session.py::TestGatewayAttachmentContext tests/run_agent/test_run_agent.py::TestAnthropicImageFallback::test_build_api_kwargs_converts_multimodal_user_image_to_text -q -n0 --timeout-method=thread`：276 通过。
  - `python -m py_compile gateway\run.py gateway\platforms\feishu.py gateway\sticker_cache.py run_agent.py`：通过。
  - `npm run test --prefix ui-tui -- src/__tests__/createGatewayEventHandler.test.ts`：43 通过。
  - `npx eslint ui-tui/src/app/createGatewayEventHandler.ts ui-tui/src/__tests__/createGatewayEventHandler.test.ts`：通过，0 错误。
  - `npm run type-check --prefix ui-tui`：通过。
  - `npm run build --prefix ui-tui`：通过，已更新 `ui-tui\dist\entry.js`。
  - `git diff --check -- gateway/run.py gateway/platforms/feishu.py gateway/sticker_cache.py run_agent.py tests/gateway/test_feishu.py tests/gateway/test_feishu_zh_progress.py tests/gateway/test_vision_memory_leak.py tests/gateway/test_stt_config.py tests/gateway/test_telegram_audio_vs_voice.py tests/gateway/test_reply_to_injection.py tests/gateway/test_sticker_cache.py tests/gateway/test_session.py tests/run_agent/test_run_agent.py ui-tui/scripts/build.mjs ui-tui/src/app/createGatewayEventHandler.ts ui-tui/src/__tests__/createGatewayEventHandler.test.ts`：通过，只有 Windows 换行提示。
  - `uv run --extra pty python scripts\tui_smoke_winpty.py --timeout 25 --marker Hermes --forbid-marker "GatewayContext missing" --forbid-marker "not TTY" --forbid-marker "maximum update depth"`：通过。
  - 运行时代码反查：`[The user ...]`、`[Replying to ...]`、`[New message]`、`I can't see animated ones yet`、`No STT provider is configured`、`trouble transcribing` 在本轮涉及的运行文件中不再作为用户/模型可见正文出现；旧英文只剩注释、测试说明或兼容旧适配器占位匹配。
  - `hermes gateway restart`：已重启飞书网关，新 PID `22004` 运行；日志确认 `✓ feishu connected`。
- 2026-05-26 通用网关命令中文化和 topic 路由稳定性验证：
  - `uv run pytest tests/gateway/test_telegram_topic_mode.py tests/test_hermes_state.py -q -n0 --timeout-method=thread`：255 通过。
  - `python -m py_compile gateway\run.py hermes_state.py`：通过。
  - `uv run pytest tests/gateway/test_feishu.py tests/gateway/test_feishu_zh_progress.py tests/gateway/test_vision_memory_leak.py tests/gateway/test_stt_config.py tests/gateway/test_telegram_audio_vs_voice.py tests/gateway/test_reply_to_injection.py tests/gateway/test_sticker_cache.py tests/gateway/test_session.py::TestSenderPrefixWithBackfill tests/gateway/test_session.py::TestGatewayAttachmentContext tests/gateway/test_telegram_topic_mode.py tests/test_hermes_state.py tests/run_agent/test_run_agent.py::TestAnthropicImageFallback::test_build_api_kwargs_converts_multimodal_user_image_to_text -q -n0 --timeout-method=thread`：531 通过。
  - `git diff --check -- gateway/run.py gateway/platforms/feishu.py gateway/sticker_cache.py hermes_state.py run_agent.py tests/gateway/test_feishu.py tests/gateway/test_feishu_zh_progress.py tests/gateway/test_vision_memory_leak.py tests/gateway/test_stt_config.py tests/gateway/test_telegram_audio_vs_voice.py tests/gateway/test_reply_to_injection.py tests/gateway/test_sticker_cache.py tests/gateway/test_session.py tests/gateway/test_telegram_topic_mode.py tests/test_hermes_state.py tests/run_agent/test_run_agent.py ui-tui/scripts/build.mjs ui-tui/src/app/createGatewayEventHandler.ts ui-tui/src/__tests__/createGatewayEventHandler.test.ts`：通过，只有 Windows 换行提示。
  - `hermes gateway restart`：已重启飞书网关，新 PID `1204` 运行；日志确认 `✓ feishu connected`。
- 2026-05-26 TUI transport 错误中文兜底验证：
  - `npm run test --prefix ui-tui -- src/__tests__/rpc.test.ts src/__tests__/createGatewayEventHandler.test.ts`：48 通过。
  - `npx eslint ui-tui/src/lib/rpc.ts ui-tui/src/app/createGatewayEventHandler.ts ui-tui/src/__tests__/rpc.test.ts ui-tui/src/__tests__/createGatewayEventHandler.test.ts`：通过，0 错误。
  - `npm run type-check --prefix ui-tui`：通过。
  - `npm run build --prefix ui-tui`：通过，已更新 `ui-tui\dist\entry.js`。
  - `git diff --check -- ui-tui/src/lib/rpc.ts ui-tui/src/app/createGatewayEventHandler.ts ui-tui/src/__tests__/rpc.test.ts ui-tui/src/__tests__/createGatewayEventHandler.test.ts`：通过，只有 Windows 换行提示。
  - `uv run --extra pty python scripts\tui_smoke_winpty.py --timeout 25 --marker Hermes --forbid-marker "GatewayContext missing" --forbid-marker "not TTY" --forbid-marker "maximum update depth"`：通过。
- 2026-05-26 TUI 斜杠菜单/命令目录中文补漏验证：
  - 修复范围：`commands.catalog`、`complete.slash`、`/details` 子项、TUI 专属命令、快捷命令失败文案、英文技能描述兜底。
  - 接口反向扫描：命令目录中 `Show/Toggle/Control/Inspect/Trigger/quick command/User commands/exec:` 等英文候选为 0；`/h` 补全英文元信息候选为 0。
  - `uv run pytest tests\tui_gateway\test_protocol.py -q -n0 --timeout-method=thread`：55 通过。
  - `uv run pytest tests\test_tui_gateway_server.py::test_complete_slash_includes_tui_details_command tests\test_tui_gateway_server.py::test_complete_slash_details_args tests\test_tui_gateway_server.py::test_commands_catalog_surfaces_quick_commands tests\test_tui_gateway_server.py::test_commands_catalog_includes_tui_mouse_command -q -n0 --timeout-method=thread`：4 通过。
  - `npm run test --prefix ui-tui -- src/__tests__/createSlashHandler.test.ts src/__tests__/useCompletion.test.ts`：61 通过。
  - `npm run type-check --prefix ui-tui`：通过。
  - `npm run build --prefix ui-tui`：通过，已更新 `ui-tui\dist\entry.js`。
  - Windows ConPTY 真实转储：`E:\AI\github\hermes-tui-zh\tests\2026-05-26-help-completion-zh.txt`，屏幕显示 `/help 显示可用命令`，未出现 `Show available commands`、`GatewayContext missing`、`not TTY`、`maximum update depth`。
- 2026-05-26 TUI 设置/模型选择/RPC 错误中文补漏验证：
  - 修复范围：模型选择器中的 `provider` 可见文案、首次设置提示、外部设置回查提示、常见 RPC 错误中文归一化。
  - 前端反向扫描：`provider + model`、`未知 provider`、`没有可用 provider`、`选择 provider`、`仍未配置 provider` 等可见候选为 0。
  - `npm run test --prefix ui-tui -- src/__tests__/rpc.test.ts src/__tests__/createSlashHandler.test.ts src/__tests__/useCompletion.test.ts src/__tests__/createGatewayEventHandler.test.ts`：110 通过。
  - `npm run type-check --prefix ui-tui`：通过。
  - `npm run build --prefix ui-tui`：通过，已更新 `ui-tui\dist\entry.js`。
  - `npx eslint ui-tui/src/lib/rpc.ts ui-tui/src/components/modelPicker.tsx ui-tui/src/app/setupHandoff.ts ui-tui/src/content/setup.ts ui-tui/src/__tests__/rpc.test.ts`：通过，0 错误。
  - Windows ConPTY 真实转储：`E:\AI\github\hermes-tui-zh\tests\2026-05-26-help-completion-zh-rpc-pass.txt`，屏幕显示 `/help 显示可用命令`，未出现 `Show available commands`、`GatewayContext missing`、`not TTY`、`maximum update depth`。
- 2026-05-27 TUI `/status` 和启动警告中文补漏验证：
  - 修复范围：`session.status` 输出、缺 API key 启动警告、空配置段健康警告。
  - `/status` 抽样输出现在为：`Hermes TUI 状态`、`会话 ID`、`位置`、`模型`、`创建时间`、`最近活动`、`令牌`、`Agent 运行中`。
  - `uv run pytest tests\test_tui_gateway_server.py::test_session_status_reads_live_gateway_agent tests\test_tui_gateway_server.py::test_tui_startup_warnings_are_localized -q -n0 --timeout-method=thread`：2 通过。
  - `uv run pytest tests\tui_gateway\test_protocol.py tests\test_tui_gateway_server.py::test_session_status_reads_live_gateway_agent tests\test_tui_gateway_server.py::test_tui_startup_warnings_are_localized tests\test_tui_gateway_server.py::test_complete_slash_details_args tests\test_tui_gateway_server.py::test_commands_catalog_surfaces_quick_commands -q -n0 --timeout-method=thread`：59 通过。
  - `pwsh -ExecutionPolicy Bypass -File E:\AI\github\hermes-tui-zh\verify.ps1 -HermesRoot E:\AI\hermes\hermes-agent`：通过，0 失败。
  - `npm run test --prefix ui-tui -- src/__tests__/rpc.test.ts src/__tests__/createSlashHandler.test.ts src/__tests__/useCompletion.test.ts src/__tests__/createGatewayEventHandler.test.ts`：110 通过。
  - `npm run type-check --prefix ui-tui`：通过。
  - `npm run build --prefix ui-tui`：通过，已更新 `ui-tui\dist\entry.js`。
  - Windows ConPTY 真实转储：`E:\AI\github\hermes-tui-zh\tests\2026-05-27-tui-zh-status-smoke.txt`，屏幕显示 `/help 显示可用命令`，未出现 `Show available commands`、`GatewayContext missing`、`not TTY`、`maximum update depth`。
- 2026-05-27 TUI emoji 对齐待办记录：
  - 用户要求：按飞书优化的思路，TUI 汉化也要补 emoji，不能只等截图发现漏项。
  - 本轮已调查但未改源码：飞书侧已有 `_FEISHU_TOOL_NAME_ZH` 和 `_FEISHU_TOOL_EMOJI`（`gateway/run.py`），TUI 侧 `ui-tui/src/lib/text.ts` 只有 `TOOL_LABELS_ZH`，工具调用显示缺少统一 emoji；`ui-tui/src/components/thinking.tsx` 的主面板标题仍是纯文本：`思考`、`工具调用`、`子任务树`、`活动`，子 Agent 折叠区也有 `思考`、`工具调用`、`进度`、`已启动子任务`。
  - 下一步实施范围：补 `TOOL_EMOJIS` 并让 `formatToolCall()` 输出 `emoji + 中文工具名`；主 ToolTrail 面板标题改为 `💭 思考`、`🧰 工具调用`、`🌿 子任务树`、`📡 活动`；子 Agent 折叠区标题改为 `💭 思考`、`🧰 工具调用`、`📈 进度`、`🌿 已启动子任务`。
  - 风险约束：不能破坏 `sameToolTrailGroup()`、`parseToolTrailResultLine()`、工具调用合并、一轮对话一个工具状态栏、滚动和输入稳定性。改完必须跑 `text.test.ts`、`createGatewayEventHandler.test.ts`、`subagentTree.test.ts`、`type-check`、`build` 和 ConPTY 启动验证。

Smoke 输出：

- `PASS: TUI started under Windows ConPTY.`
- 启动入口：`E:\AI\hermes\hermes-agent\ui-tui\dist\entry.js`

## 下一步

下一步不要重做布局：

1. 修正或新增交互验证器：现有 ConPTY 手工输入能把 `/mem` 写进输入框，但没有可靠触发 Enter，不能作为命令执行验收依据。
2. 真实 TUI 交互截图验收：`/help`、`/model`、`/agents`、`/browser`、`/skills`、`/mem`、`/fortune`。
3. 若用户确认视觉方向，再做布局/美化，不和汉化混在一起。
