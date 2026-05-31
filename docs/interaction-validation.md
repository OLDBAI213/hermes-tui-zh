# 交互验证记录

日期：2026-05-25

## 2026-05-30 长流程隔离验收修复

本轮确认早先长流程验收脚本曾共用真实 Hermes 现场，可能污染用户正在使用的 TUI 会话。已改为默认隔离：

- 每次运行都会在输出目录下创建独立 `HERMES_HOME` 和独立工作目录。
- 隔离目录会写入一次性本地假 provider 配置，只用于让 TUI/slash 流跑起来，不使用真实 API key。
- `--use-real-hermes-home` 只保留给诊断，不作为默认验收入口。
- 退出清理改为限时关闭，避免 pywinpty 卡住后留下长流程验收进程。

最新真实长流程通过：

- 报告：`tests/long-run-acceptance/2026-05-30-isolated-check/long-run-acceptance.md`
- 覆盖：启动、`/help`、`/mem`、`/browser status`、`/voice status`、本地 shell 失败中文标签、`/status`、窄窗口 resize。
- 报告中明确记录 `隔离环境：是`，并写出独立 `HERMES_HOME` 与工作目录。
- 进程复查：未留下 `tui-long-run-acceptance.py` 残留进程。

同次修复小米 MiMo 图片链路：

- TUI 附图在 `xiaomi/mimo-v2.5` 下走主模型原生多模态，不再调用外部 `vision_analyze`，避免外部视觉 Key 401 影响主模型看图。
- `vision_analyze` 只保留给图片不在当前上下文、显式文本管线或非视觉模型；原生多模态工具面会隐藏该工具。
- agent 内部工具返回截图时保留 provider 拒绝后的文本回退，避免真实不兼容时重复触发 `Error code: 400 ... text is not set`。

验证：

- `uv run pytest tests\agent\test_image_routing.py tests\test_model_tools.py::TestNativeVisionToolFiltering tests\tools\test_vision_tools.py::TestVisionRequirements tests\run_agent\test_multimodal_tool_content_recovery.py tests\test_tui_gateway_server.py::test_tui_native_image_parts_use_xiaomi_nested_shape tests\test_tui_gateway_server.py::test_tui_does_not_force_text_mode_for_xiaomi_mimo tests\test_tui_gateway_server.py::test_enrich_with_attached_images_uses_chinese_fallback tests\tui_gateway\test_protocol.py::test_commands_catalog_localizes_tui_descriptions tests\test_tui_gateway_server.py::test_session_status_reads_live_gateway_agent -q -n0 --timeout-method=thread`：通过。
- `E:\AI\github\hermes-tui-zh\verify.ps1`：通过，`Failed: 0`。
- `scripts\tui-long-run-acceptance.py` 隔离长流程：PASS。

## 结论

当前静态汉化检查和 TUI 启动冒烟通过，但 slash 命令的自动交互验证还不能作为通过证据。

原因不是 `/mem`、`/fortune` 或汉化源码本身，而是现有 ConPTY 验证脚本只能把命令写入输入框，没有可靠触发 TUI 的 Enter 提交路径。测试中尝试过普通回车、控制键回车、CSI u 回车，命令仍停留在输入行。

2026-05-25 追加确认：逐字符输入 `/mem`、尾随空格规避补全、以及 `LF`、`CRLF`、`CSI u`、`modifyOtherKeys`、`sendcontrol('m')` 五种 Enter 方式都没有稳定触发提交。现象是 slash 补全框会出现，输入行能看到 `/mem`，但命令没有进入执行结果区域。

## 已确认

- TUI 能在 Windows ConPTY 下启动。
- `verify.ps1` 已覆盖 P0/P1/P2 汉化关键字符串和旧英文回潮检查。
- `npm run type-check` 通过。
- 思考状态词已补：`REASONING_STATUS_WORDS` 不再使用 `pondering`、`reasoning`、`brainstorming` 等英文。
- 历史/模型输出中的旧英文思考状态词会从展示预览中过滤，例如 `reflecting`、`cogitating`。
- 空闲状态栏不再显示 `语音 关`。
- 当前本机已确认 `E:\AI\hermes\config.yaml` 需要保持 `display.mouse_tracking: true`。如果关闭，终端可能把滚轮转成 Up/Down，TUI 会按输入历史切换处理，表现为滚轮把上一条消息放进输入框，而不是滚动对话。

## 下一步验收口径

1. 先修一个可靠的交互验证器，要求能提交 slash 命令，而不是只把文字写到输入框。
2. 再验收 `/help`、`/model`、`/agents`、`/browser`、`/skills`、`/mem`、`/fortune` 的真实 TUI 输出。
3. 交互验证没过前，只能说“静态验证和启动验证通过”，不能说“全部交互已验收”。

## 2026-05-27 emoji 对齐补充

用户明确要求 TUI 汉化按飞书优化补 emoji。当前记录口径：

- 飞书侧已经有工具名中文 + emoji 映射，TUI 侧还没有同等映射。
- TUI 优先补不会改变布局结构的入口：工具调用行、主面板标题、子 Agent 折叠标题。
- 验收必须确认 emoji 不导致宽度错位、输入行跳动、工具记录无法合并、滚动异常。
- 自动验证先覆盖字符串和状态合并；真实 ConPTY 验证先看启动和 `/help`，slash 命令执行验证器仍需单独修。

## 2026-05-27 emoji 对齐实现

已完成第一轮不改布局结构的 emoji 对齐：

- 工具调用行现在显示 `emoji + 中文工具名`，例如 `📖 读取文件`、`🔎 搜索文件`、`📚 查看技能`、`🧪 浏览器 CDP`。
- 工具记录合并逻辑已兼容旧纯中文标签和新 emoji 标签，避免同一个工具开始/完成显示成两行。
- 主面板标题已加图标：`💭 思考`、`🧰 工具调用`、`🌿 子任务树`、`📡 活动`。
- 子 Agent 折叠标题已加图标：`💭 思考`、`🧰 工具调用`。
- 委托任务加 `🧩` 后仍保持内联子任务树识别，不把子任务树错误挪成单独面板。

本轮真实 ConPTY 启动验证通过，输出：`tests/2026-05-27-tui-emoji-smoke.txt`。slash 命令自动提交问题仍未解决，不能把 `/mem`、`/fortune` 等真实命令执行结果算作已自动验收。

## 2026-05-27 工具/思考显示修复

用户截图暴露两点：工具调用仍显示成代码式英文动作，思考区没有实际显示。已改为：

- 本机 TUI 配置恢复 `display.show_reasoning: true`，并让 `sections.thinking`、`sections.tools` 默认展开；飞书 reasoning 仍保持关闭。
- 工具调用上下文改为中文动作和冒号样式，例如 `⏰ 定时任务：查看列表`、`⏰ 定时任务：删除任务`，不再优先显示 `Cronjob("list")` 这类函数形态。
- 活动工具行用独立字段保存 label/duration/spinner，不再把 React 片段转字符串解析，降低正在执行工具时显示错乱的风险。
- 英文 reasoning 根因已定位：当前 `xiaomi / mimo-v2.5` 会返回原生 `delta.reasoning_content`，即使系统提示要求中文，这个字段仍可能是英文。TUI 不再把英文原文直接露给用户，改为中文状态摘要。

已通过单元测试、定向 eslint、后端 prompt 注入测试、type-check、build、`node --check` 和 Windows ConPTY 启动验证，输出：`tests/2026-05-27-tui-reasoning-zh-smoke.txt`。后续仍需真实交互验证器能稳定提交 slash 命令后，再把具体 `/mem`、`/fortune` 执行结果纳入自动验收。

## 2026-05-27 模型进度显示修复

用户截图暴露“明明在干活但 TUI 主面板像卡住”的问题。调查确认后端仍在运行，问题是模型长等待阶段没有进入主工具轨迹区。已修复：

- 后端在每次模型调用开始、等待心跳、首个返回、调用完成时发 `status.update(kind=model)`。
- 前端把模型状态显示为 `模型：等待响应 #n…`、`模型：仍在等待响应 · 已等待 Ns`、`模型：响应完成 #n · Ns`，并替换“正在分析工具输出…”。
- 后台 self-improvement review 在 TUI 下会先延后；如果用户已经发起下一轮前台任务，则跳过本轮后台 review，避免静默抢占模型。
- 新增回归测试覆盖模型状态去重、工具后占位替换、TUI 前台忙时跳过后台 review。

本轮真实 ConPTY 启动验证通过，输出：`tests/2026-05-27-tui-model-progress-smoke.txt`。这只能证明 TUI 启动链稳定；长模型等待的肉眼验证还需要后续真实任务或交互验证器补齐。

## 2026-05-27 slash 命令自动提交修复

已修复 Windows ConPTY 验证器只能输入、不能稳定提交 slash 命令的问题：

- 新增 `--slash-command`，会把 `/status` 这类命令作为真实输入提交。
- 真实根因是 slash 补全菜单会在自动化路径里截住 Enter；验证器现在给 slash 命令补一个尾随空格，再发送独立 Enter。
- 新增 `--before-input-delay`，可等 TUI 恢复到 `就绪` 后再输入命令，避免会话还没建立时误报“没有活动会话”。
- 已用 `/status` 验通真实输出，转储：`tests/2026-05-27-tui-status-command-smoke.txt`，其中包含 `Hermes TUI 状态`、`会话 ID`、`模型`、`Agent 运行中`。

后续可以把 `/help`、`/mem`、`/fortune` 等命令逐步纳入真实 ConPTY 自动验收。

## 2026-05-27 显示质量门收口

针对“不能看见一个改一个”的问题，已新增集中质量门：

- 前端集中契约测试：`ui-tui/src/__tests__/tuiDisplayContract.test.ts`
- 后端显示契约测试：`tests/test_tui_display_contract.py`
- 质量门说明：`docs/tui-display-quality-gate.md`

这个质量门把工具调用中文化、英文 reasoning 摘要、模型进度轨迹、旧构建提示、配置漂移提示、slash 自动提交放到一组固定检查里。后面再改 TUI 显示，必须跑这组检查，不能只靠截图确认。

## 2026-05-27 模型进度平台隔离修复

用户新截图暴露：`等待响应 #20…`、`开始返回 #20…`、`响应完成 #20` 这类 TUI 专用模型进度被 Feishu/聊天平台当成普通消息发出。根因是后端把模型进度挂在通用 `status_callback("model", ...)` 上，网关出口没有区分平台。

已改为两层保护：

- 源头：模型进度只在 `platform == "tui"` 时通过 `emit_tui_model_status()` 发出。
- 出口：通用网关 `_prepare_gateway_status_message()` 对 `event_type == "model"` 直接丢弃，避免后续误接入再次污染 Feishu/Telegram/Discord。

这类进度仍会显示在 TUI 工具轨迹里，但不会再生成聊天气泡。

验证结果：

- 源头隔离测试 3 条通过：非 TUI 平台不会触发模型进度回调，TUI 会触发，异常回调被吞掉并记录 debug。
- 网关出口测试通过：Feishu、Telegram、Discord 收到 `event_type == "model"` 时返回 `None`，不会发送平台消息。
- 本地质量门 `verify.ps1` 0 失败；其中同时检查了 TUI reasoning/tools 配置、模型进度瞬态轨迹、出口拦截和测试文件存在。
- Windows ConPTY 已真实提交 `/status`，转储为 `tests/2026-05-27-tui-model-status-isolation-smoke.txt`。
- 飞书网关已重启，PID `38040`，日志显示 `✓ feishu connected`。

## 2026-05-27 当前轮次概览升级

这次按“先让主流程不断片”处理，没有重做布局：

- 新增当前轮次阶段状态：等待模型、开始返回、工具调用中、正在分析工具输出、工具失败。
- 工具阶段会显示运行中/完成/失败计数。
- 工具失败会在 TUI 里显示“失败原因：...”，避免用户只能看到工具调用停住。
- 当前轮次概览不挂在默认隐藏的 `activity` 独立区；只要工具区可见，就能看到。

验证结果：

- `createGatewayEventHandler.test.ts`、`tuiDisplayContract.test.ts`、`text.test.ts`：82 通过。
- `npm run type-check --prefix ui-tui`：通过。
- 定向 eslint：0 错误，仅 `useMainApp.ts` 既有 4 个 warning。
- `npm run build --prefix ui-tui`：通过。
- Windows ConPTY `/status` 真实提交通过，转储：`tests/2026-05-27-tui-turn-phase-smoke.txt`。

## 2026-05-27 TUI 启动卡顿修复

本轮调查确认一个启动级卡点：TUI 网关在 `gateway.ready` 前同步执行 MCP 工具发现，遇到慢 MCP server 时首屏会被拖住，表现为“明明在干活但界面卡住/网关启动超时”。

已改为：

- 先发送 `gateway.ready`，再后台发现 MCP。
- 后台 MCP 完成后刷新活跃 TUI 会话的工具列表。
- agent 还没初始化完时先记待刷新，初始化完成后自动补刷。

当前已通过启动顺序和工具刷新单元测试。后续 ConPTY `/status` 验证会继续作为真实启动链路验收。

补充验证结果：

- 启动首包复测：`gateway.ready` 约 2.4 秒返回，`session.create` 约 2.5 秒返回；不再等待慢 MCP 超时。
- Windows ConPTY `/status` 真实提交通过，转储：`tests/2026-05-27-tui-mcp-startup-smoke.txt`。
- 转储中包含 `Hermes TUI 状态`，未出现 `GatewayContext missing`、`not TTY`、`maximum update depth`。
