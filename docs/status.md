# 状态

日期：2026-05-26

## 2026-05-30 可见英文总账硬门

这次不再只按截图补单句，新增 TUI 可见英文 AST 审计：

- 审计脚本：`E:\AI\github\hermes-tui-zh\scripts\audit-visible-text.mjs`
- 白名单：`E:\AI\github\hermes-tui-zh\allowlist\tui-visible-english.json`
- 报告：`E:\AI\github\hermes-tui-zh\tests\visible-text-report.md`

本轮审计结果：

- 初始未批准可见英文：248。
- 修复后未批准可见英文：0。
- `verify.ps1` 已接入硬门：`TUI visible English audit passed`。

同步修复了审计命中的真实可见出口：斜杠命令、会话编排器、启动/关闭/恢复状态、语音提示、模型/工具详情、技能/工具面板、终端设置错误、动态工具详情标签（`参数` / `结果` / `错误`）。

验证：

- `node E:\AI\github\hermes-tui-zh\scripts\audit-visible-text.mjs --hermes-root E:\AI\hermes\hermes-agent --report E:\AI\github\hermes-tui-zh\tests\visible-text-report.md`：通过，`Unapproved: 0`。
- `pwsh -NoProfile -ExecutionPolicy Bypass -File E:\AI\github\hermes-tui-zh\verify.ps1 -HermesRoot E:\AI\hermes\hermes-agent`：通过，`Failed: 0`，包含可见英文硬门。
- `npm run type-check`（`E:\AI\hermes\hermes-agent\ui-tui`）：通过。
- `npx vitest run src/__tests__/createSlashHandler.test.ts src/__tests__/createGatewayEventHandler.test.ts src/__tests__/activeSessionSwitcher.test.ts src/__tests__/text.test.ts`：4 文件、142 测试通过。
- 完整升级口：`E:\AI\github\_60-reviews\hermes-upgrade-gate\2026-05-30-010224\upgrade-gate.md`，所有项目 PASS。

当前等级提升为 B+：本机自动验收、升级口、隔离长流程 TUI 交互验收均通过；仍缺人工截图/肉眼验收，所以不是发布级 A。

## 2026-05-30 长流程隔离和 MiMo 图片错误修复

用户截图暴露 `xiaomi/mimo-v2.5` 下的 `Error code: 400 ... text is not set`。调查确认两件事：

- 早先长流程验收脚本共用了真实 Hermes 现场，属于测试污染风险。
- Hermes 把已经在主模型上下文里的图片又交给外部 `vision_analyze`，外部视觉 Key 无效时就出现 401；同时旧文档误把 MiMo 修成“必须文本降级”，会反向削弱原生多模态。

已修复：

- `scripts/tui-long-run-acceptance.py` 默认使用独立 `HERMES_HOME` 和独立工作目录，并写入一次性本地假 provider 配置；不会再写入真实用户会话。
- `agent.image_routing` 在 `auto` 模式下优先相信主模型原生视觉能力；旧的 `auxiliary.vision` 配置不再抢走图片。
- `model_tools.py` 在主模型原生多模态时隐藏 `vision_analyze`，并把该状态纳入工具缓存键，避免重启/切模型后拿到旧工具面。
- `tools/vision_tools.py` 的状态检查不再因外部视觉 Key 无效，把原生视觉主模型标成不可用。
- TUI、CLI、Gateway 的附图入口统一走主模型原生图片输入；工具结果图片只在 provider 真实拒绝后降级为文本摘要。

验证：

- 隔离长流程：`tests/long-run-acceptance/2026-05-30-isolated-check/long-run-acceptance.md`，PASS，覆盖 `/help`、`/mem`、`/browser status`、`/voice status`、本地 shell 失败中文标签、`/status`、窄窗口 resize。
- 定向回归覆盖：MiMo 原生图片路由、原生多模态隐藏 `vision_analyze`、视觉状态检查、工具结果图片拒绝后的文本回退、TUI 附图不强制文本降级。
- `verify.ps1`：通过，`Failed: 0`。
- 进程复查：未留下 `tui-long-run-acceptance.py` 残留进程。

## 2026-05-30 兼修收口

当前 Hermes 源码是 `E:\AI\hermes\hermes-agent`，版本 `Hermes Agent v0.15.1 (2026.5.29)`。

结论：`hermes-tui-zh` 已重新适配当前 v0.15.1 的分拆 TUI 源码结构，本机验证恢复通过。

本轮修复覆盖：

- `setup`、placeholder、hotkey、submission、setup handoff、session lifecycle、queued panel、todo、overlay、model picker、debug/ops/session slash help 等 TUI 可见中文回流。
- 旧英文 legacy text 清单收敛，包括 `session not ready yet`、`Ctrl+C to interrupt`、`Select model`、`setup required`、`gateway exited`、`Tool calls`、`caps d` 等。
- TUI 专用模型进度、会话配置警告展示、后台 MCP discovery 后刷新 live session 的 readiness 等适配缺口。
- `createSlashHandler` / `createGatewayEventHandler` 测试断言同步到当前中文文案，避免核心扩展验证被旧英文断言拖红。

验证：

- `pwsh -NoProfile -ExecutionPolicy Bypass -File E:\AI\github\hermes-tui-zh\verify.ps1 -HermesRoot E:\AI\hermes\hermes-agent`：通过，`Failed: 0`。
- `npm run type-check --prefix E:\AI\hermes\hermes-agent\ui-tui`：通过。
- `npm run test --prefix E:\AI\hermes\hermes-agent\ui-tui -- src/__tests__/createGatewayEventHandler.test.ts src/__tests__/tuiDisplayContract.test.ts src/__tests__/runtimeFreshness.test.ts`：3 文件、50 测试通过。
- `uv run pytest tests/test_tui_gateway_server.py -k "refresh_mcp_tools or session_create_no_race_keeps_worker_alive" --timeout-method=thread`：3 通过。
- `pwsh -NoProfile -ExecutionPolicy Bypass -File E:\AI\github\hermes-tui-extension-core\verify.ps1 -HermesHome E:\AI\hermes -RunTests`：前端 115 测试、后端 7 测试通过。
- 完整升级口：`E:\AI\github\_60-reviews\hermes-upgrade-gate\2026-05-30-002411\upgrade-gate.md`，所有项目 PASS。

证据：

- 修复前兼修包：`E:\AI\github\_50-issues\hermes-compat-repair\2026-05-29-233916-hermes-tui-zh\compat-repair.md`。
- 修复后日志：`E:\AI\github\_50-issues\hermes-compat-repair\2026-05-29-233916-hermes-tui-zh\evidence\verify-after.log`。

限制：这次恢复到“本机可用 B”，不是发布级 A；还缺真实长流程 TUI 截图/交互验收。

## 2026-05-29 复审历史

当前 Hermes 源码是 `E:\AI\hermes\hermes-agent`，版本 `Hermes Agent v0.15.1 (2026.5.29)`。

结论：当时本项目不再完整适配当前 Hermes。旧验收脚本依赖的 `ui-tui/src/content/zh.ts` 已不存在，当前源码改为分拆内容文件。`verify.ps1` 已修正为不因缺文件崩溃，并会继续扫描当前文件结构。

复审结果：

- `pwsh -ExecutionPolicy Bypass -File E:\AI\github\hermes-tui-zh\verify.ps1 -HermesRoot E:\AI\hermes\hermes-agent`：失败，`Failed: 113`。
- 已确认仍保留的能力：TUI display contract、英文 reasoning 中文摘要、工具 emoji/中文标签、TUI-only model status 出口拦截、ConPTY smoke 参数等。
- 主要缺口：setup、placeholder、hotkey、queue、slash help、model picker、overlay、todo、fortune/charm/verb、terminal setup 等前端可见文案大量回到英文。

因此旧的“P0/P1/P2 已完成、verify 0 失败”只代表 2026-05-27 之前的源码快照。该漂移已在 2026-05-30 收敛；本段保留为修复前证据。

## 当前状态

P0 主流程汉化 + P1 高频入口汉化 + P2 低频外壳补漏已直接落到 Hermes 原生 TUI 源码。2026-05-25 又补了思考状态词、首次设置状态、状态栏语音占位、滚轮配置、遮罩弹层、任务面板、启动/恢复/运行状态、协议噪声、命令目录、MCP 自动重载、语音连续模式停止、`/skills` 和 `/tools` 标题/空输出：`REASONING_STATUS_WORDS` 已从英文改为中文，历史 reasoning 里的 `reflecting`/`cogitating` 会过滤，表情状态前缀也会清掉，缺少 provider 时不再显示 `setup required`，空闲状态不再显示 `语音 关`，`display.mouse_tracking` 已恢复为 `true`，sudo/secret/pager 弹层提示已汉化，任务面板不再显示 `Todo` / `incomplete`。

2026-05-26 补充：修复一轮回复已经显示后，后台记忆/待办等收尾工具还在运行时状态栏只显示随机“正在做”的问题。现在这类场景会显示“回答已生成，后台收尾…”，审批、等待输入、工具准备等明确状态也不会再被状态动画盖住。本机 `E:\AI\hermes\config.yaml` 已恢复 TUI 思考显示：`display.show_reasoning: true`，`display.sections.thinking: expanded`；飞书侧 `display.platforms.feishu.show_reasoning` 仍保持 `false`，没有误改飞书显示规则。

2026-05-26 晚间补充：重点排查“思考/思维链汉化一会有一会没有”。结论是三类来源混在一起：TUI 面板标题/状态词是前端文案，应该稳定中文；模型实时返回的 `reasoning` / `reasoning_content` 是供应商原文，会出现英文；历史会话里已经存下的英文 reasoning 也会被回放。最新会话样本 `session_20260526_150922_ed4651.json` 中 486 条 reasoning 字段里 328 条偏英文，证明问题主要来自模型原文和历史缓存，不是单个标题漏翻。已做的修正：TUI 自身的 `tokens` 显示改成“令牌”；网关中文规则加强，明确要求可见 thinking/reasoning 不用 `Let me` / `I should` 等英文开头；TUI 本机配置保持 `show_reasoning: true` 和 `sections.thinking: expanded`。2026-05-27 起，TUI 检测到英文 reasoning 时不再显示原文，而是改为中文状态摘要。

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
- 2026-05-27 TUI emoji 对齐实现：
  - 已在 `ui-tui/src/lib/text.ts` 增加 `TOOL_EMOJIS`、`toolTrailDisplayLabel()` 和带 emoji 的 `formatToolCall()` 输出，覆盖读取/写入文件、搜索、技能、浏览器、视觉分析、定时任务、GitHub MCP 等常见工具。
  - `sameToolTrailGroup()` 已兼容“纯中文旧标签”和“emoji + 中文新标签”，避免完成态替换、工具合并、后台收尾记录被拆成重复行。
  - 主 ToolTrail 面板标题已改为 `💭 思考`、`🧰 工具调用`、`🌿 子任务树`、`📡 活动`；子 Agent 折叠区已改为 `💭 思考`、`🧰 工具调用`。
  - 已保留委托任务内联子任务树识别，避免 `🧩 委托任务` 加图标后把子任务树挤到独立面板。
  - 验证：`text.test.ts`、`createGatewayEventHandler.test.ts`、`subagentTree.test.ts` 共 108 通过；定向 eslint 0 错误；`type-check` 通过；`build` 通过；ConPTY 启动通过，输出见 `tests/2026-05-27-tui-emoji-smoke.txt`。
- 2026-05-27 截图反馈修复：用户截图暴露 TUI 工具调用仍像 `Cronjob("list")`，且思考区没有显示。已确认直接原因之一是本机 `E:\AI\hermes\config.yaml` 里 `display.show_reasoning: false`、`sections.thinking/tools: collapsed`，前端会因此丢弃 reasoning。现在 TUI 已恢复 `show_reasoning: true`，`thinking/tools` 默认展开；飞书侧 `display.platforms.feishu.show_reasoning: false` 仍保持不变。
- 同次优化工具调用展示：`formatToolCall()` 改为 `emoji + 中文工具名：中文动作/上下文`，例如 `⏰ 定时任务：查看列表`、`⏰ 定时任务：删除任务`、`📖 读取文件：x`；活动中的工具行不再把 spinner 片段转成字符串再解析，避免出现对象化/错位显示。
- 同次定位英文 reasoning 根因：本机当前路由是 `xiaomi / mimo-v2.5`，`agent.reasoning_effort: high`，模型会通过 OpenAI-compatible 流式 `delta.reasoning_content` 返回原生 thinking；`agent.system_prompt` 和 TUI 注入规则已经要求中文，但该原生字段不保证服从语言要求。TUI 之前只是把 provider 原文字段忠实展示出来。
- 同次修正显示策略：TUI 不再直接露出英文 reasoning 原文；检测到英文 reasoning 时改成中文状态摘要，例如截图里的 `The path resolution is wrong...` 会显示为“路径解析不正确，正在修正路径并重试。”，不再用“中文提示 + 英文正文”的形式。
- 2026-05-27 TUI 启动提示和交互验证器继续优化：
  - 后端启动健康检查新增 `display.show_reasoning: false`、`display.sections.thinking/tools: hidden` 的中文提醒；后续 `session.info` 事件里的 `credential_warning`、`config_warning` 现在会真正显示到 TUI 对话区。
  - 前端新增旧构建检测：如果当前窗口启动后 `ui-tui\dist\entry.js` 被重新构建，会提示重启 TUI 窗口加载最新显示修复。
  - Windows ConPTY 验证器新增 `--slash-command` 和 `--before-input-delay`，已经能提交 `/status` 并验证真实输出。
  - 验证转储：`tests/2026-05-27-tui-status-command-smoke.txt`，包含 `Hermes TUI 状态`、`会话 ID`、`模型`、`Agent 运行中`。
- 同次验证：`text.test.ts`、`createGatewayEventHandler.test.ts`、`subagentTree.test.ts` 共 109 通过；定向 eslint 0 错误；TUI 后端中文 reasoning 注入测试 1 通过；`type-check` 通过；`build` 通过；`node --check ui-tui\dist\entry.js` 通过；Windows ConPTY 启动通过，输出见 `tests/2026-05-27-tui-reasoning-zh-smoke.txt`。`verify.ps1` 已新增 TUI reasoning/tools 可见性、工具动作中文和英文 reasoning 中文摘要检查。

- 2026-05-27 TUI 模型进度显示修复：
  - 根因：工具完成后到下一次模型返回之间，后端只更新内部 `_touch_activity()` 和底部状态栏，主工具轨迹区仍停在“正在分析工具输出…”或上一段思考；长模型请求 40-80 秒时看起来像卡住。
  - 已在后端补 `status.update(kind=model)`：等待响应、等待心跳、开始返回、响应完成都会发给 TUI。
  - TUI 收到 `kind=model` 后写入工具轨迹区为 `模型：...`，并替换旧模型占位和“正在分析工具输出…”，避免堆出多行重复状态。
  - TUI 后台 self-improvement review 增加前台忙碌门：TUI 下先延后 8 秒；如果这期间已有新前台任务，则跳过本轮后台 review，避免它悄悄和用户任务抢模型。
  - 验证：`createGatewayEventHandler.test.ts` / `text.test.ts` 共 76 通过；后台 review 相关测试 10 通过；定向 eslint 0 错误；`type-check` 通过；`build` 通过；`node --check ui-tui\dist\entry.js` 通过；Windows ConPTY 启动通过，输出见 `tests/2026-05-27-tui-model-progress-smoke.txt`。
- 2026-05-27 TUI 显示质量门收口：
  - 新增 `ui-tui/src/__tests__/tuiDisplayContract.test.ts`：集中覆盖工具调用中文化、英文 reasoning 摘要、模型进度瞬态轨迹、旧构建提示。
  - 新增 `tests/test_tui_display_contract.py`：集中覆盖后端 `session.info` 显示健康、配置漂移中文提示、ConPTY slash 提交护栏。
  - 新增 `docs/tui-display-quality-gate.md`：固定后续 TUI 显示改动必须跑的质量门，避免继续按截图逐项补漏。
  - `verify.ps1` 已接入这些契约文件和关键字符串检查。
- 2026-05-27 模型进度平台隔离修复：
  - 用户截图中的 `等待响应 #20…`、`开始返回 #20…`、`响应完成 #20` 连续气泡不是模型正文，而是 TUI 专用模型进度误走了 Feishu/聊天网关。
  - 已新增 `agent/status_events.py::emit_tui_model_status()`，源头只允许 `platform == "tui"` 发模型进度。
  - `gateway/run.py::_prepare_gateway_status_message()` 已对 `event_type == "model"` 做出口拦截，Feishu、Telegram、Discord 等平台不会再收到这类 TUI 进度气泡。
  - 回归测试新增 `tests/agent/test_status_events.py` 和 `tests/gateway/test_feishu_zh_progress.py::test_gateway_model_status_is_tui_only_not_platform_message`。
  - 本机 `E:\AI\hermes\config.yaml` 已再次恢复 TUI 思考显示：顶层 `display.show_reasoning: true`、`display.sections.thinking: expanded`、`display.sections.tools: expanded`；飞书平台覆盖项 `display.platforms.feishu.show_reasoning: false` 保持不变。
  - 已重启飞书网关，新 PID `38040`，日志确认 `✓ feishu connected`，新出口规则已进入运行态。

同次验证：

- `python -m py_compile agent\conversation_loop.py agent\chat_completion_helpers.py agent\status_events.py gateway\run.py`：通过。
- `uv run pytest tests/agent/test_status_events.py tests/gateway/test_feishu_zh_progress.py::test_gateway_model_status_is_tui_only_not_platform_message tests/gateway/test_feishu_zh_progress.py::test_feishu_status_callback_uses_lifecycle_localization -q -n0 --timeout-method=thread`：5 通过。
- `uv run pytest tests/gateway/test_feishu_zh_progress.py tests/gateway/test_telegram_noise_filter.py -q -n0 --timeout-method=thread`：30 通过。
- `uv run pytest tests/test_tui_display_contract.py tests/test_tui_gateway_server.py::test_tui_startup_warnings_are_localized -q -n0 --timeout-method=thread`：4 通过。
- `npm run test --prefix ui-tui -- src/__tests__/tuiDisplayContract.test.ts src/__tests__/createGatewayEventHandler.test.ts src/__tests__/runtimeFreshness.test.ts`：52 通过。
- `npm run type-check --prefix ui-tui`：通过。
- `npm run build --prefix ui-tui`：通过，已更新 `ui-tui\dist\entry.js`。
- `node --check ui-tui\dist\entry.js`：通过。
- `pwsh -ExecutionPolicy Bypass -File E:\AI\github\hermes-tui-zh\verify.ps1 -HermesRoot E:\AI\hermes\hermes-agent`：通过，0 失败。
- Windows ConPTY `/status` 真实提交：通过，输出见 `tests/2026-05-27-tui-model-status-isolation-smoke.txt`。
- 源码反查：运行时代码中不再有直接 `status_callback("model", ...)`；只剩 `emit_tui_model_status()` 和网关 `event_type == "model"` 出口拦截。
- 2026-05-27 TUI 当前轮次概览升级：
  - 新增 `TurnPhase` 状态，TUI 会持续显示当前阶段：等待模型、开始返回、工具调用中、正在分析工具输出、工具失败。
  - 当前轮次概览会显示运行中/完成/失败工具计数；工具失败时显示“失败原因：...”，避免用户只看到卡住或一串工具名。
  - 概览挂在工具/活动可见区域，默认 `activity: hidden` 时仍能随工具区显示，不依赖额外打开活动面板。
  - 新增回归测试覆盖模型等待、工具开始、工具完成、工具失败的阶段状态。
  - 验证：`createGatewayEventHandler.test.ts`、`tuiDisplayContract.test.ts`、`text.test.ts` 共 82 通过；`type-check` 通过；定向 eslint 0 错误（仅 `useMainApp.ts` 既有 4 个 warning）；`build` 通过；Windows ConPTY `/status` 真实提交通过，输出见 `tests/2026-05-27-tui-turn-phase-smoke.txt`。

Smoke 输出：

- `PASS: TUI started under Windows ConPTY.`
- 启动入口：`E:\AI\hermes\hermes-agent\ui-tui\dist\entry.js`

## 下一步

下一步不要重做布局：

1. 用新的 `--slash-command` 逐步把 `/help`、`/model`、`/agents`、`/browser`、`/skills`、`/mem`、`/fortune` 加进真实 ConPTY 命令验收。
2. 继续反向扫 TUI 可见英文，优先补模型选择、错误弹层、子任务/工具详情里的剩余长句。
3. 布局美化仍等交互验收稳定后再做，避免显示质量门还没稳时扩大改动面。

## 2026-05-27 TUI 启动卡顿修复

用户截图里的 `运行状态` 能显示，但真实卡点在启动链路：`tui_gateway.entry` 会先同步发现 MCP 工具，再发送 `gateway.ready`。本机配置里 `obsidian` MCP 连接超时会拖住约 60-70 秒，导致 TUI 停在“网关启动超时/正在恢复”。

已修复：

- `gateway.ready` 先发出，TUI 首屏不再等待 MCP/外部工具发现。
- MCP 工具发现转后台线程执行；发现完成后调用 `refresh_mcp_tools_for_sessions()` 刷新已就绪 TUI 会话。
- 如果 MCP 发现完成时 agent 还在初始化，会标记 `mcp_tools_refresh_pending`，agent 就绪后再补刷，避免第一会话少工具。
- `AIAgent.refresh_tools()` 已补齐，会重建工具面、保留 memory/context-engine 动态工具，并刷新 system prompt 缓存。
- 质量门已新增启动顺序和工具刷新回归测试，防止后续又把慢外部依赖放回启动主链路。

验证：

- `tests/tui_gateway/test_entry_startup.py` 和 `tests/test_tui_gateway_server.py` 的 MCP 刷新窄测：5 通过。
- Python 编译：`tui_gateway\entry.py`、`tui_gateway\server.py`、`run_agent.py` 通过。
- 后端显示/协议回归：`tests/test_tui_display_contract.py tests/tui_gateway/test_protocol.py`，58 通过。
- 前端契约：`text.test.ts`、`tuiDisplayContract.test.ts`、`createGatewayEventHandler.test.ts`，84 通过。
- `npm run type-check --prefix ui-tui`：通过。
- `npm run build --prefix ui-tui`：通过，已更新 `ui-tui\dist\entry.js`。
- `node --check ui-tui\dist\entry.js`：通过。
- `verify.ps1`：通过，0 失败，并已覆盖 TUI MCP 后台发现、会话刷新和 pending 竞态。
- 启动首包复测：之前同步 MCP 路径约 73 秒；现在 `gateway.ready` 约 2.4 秒返回，`session.create` 约 2.5 秒返回。
- Windows ConPTY `/status`：通过，输出见 `tests/2026-05-27-tui-mcp-startup-smoke.txt`，包含 `Hermes TUI 状态`，未出现 `GatewayContext missing`、`not TTY`、`maximum update depth`。

注意：已打开的旧 TUI 窗口仍运行旧 `dist\entry.js`，需要重启 TUI 窗口才能加载这次启动修复。
