# TUI 汉化 Inventory

本文件用于记录审查结果。状态说明：

- `zh`: 已汉化或已有中文显示。
- `keep`: 必须保留英文原文。
- `explain`: 保留原文，但需要中文解释。
- `todo`: 需要补汉化。
- `test`: 测试字符串，不进入用户界面。

## 2026-05-24 第一轮审查

目标仓库：`E:\AI\hermes\hermes-agent`

### P0 主流程

| 模块 | 状态 | 说明 |
| --- | --- | --- |
| `src/content/zh.ts` | zh | 主对话、错误、队列、剪贴板图片、工具空结果已集中汉化。 |
| `src/app/useSubmission.ts` | zh | 会话未就绪、提交失败、队列提示走 `ZH`。 |
| `src/app/turnController.ts` | zh | 中断提示、工具输出分析提示已汉化；工具名本身保留原文。 |
| `src/components/appLayout.tsx` | zh | 输入区忙碌提示已汉化。 |
| `src/components/messageLine.tsx` | zh | 空工具结果等主展示走 `ZH`。 |

### P1 高频命令和面板

| 模块 | 状态 | 说明 |
| --- | --- | --- |
| `src/app/slash/commands/core.ts` | zh | `/help`、`/mouse`、`/status`、`/details`、`/copy`、`/history`、`/save`、`/queue`、`/steer`、`/undo` 等第一轮汉化。命令语法保留英文参数。 |
| `src/app/slash/commands/session.ts` | zh | `/model`、`/personality`、`/compress`、`/skin`、`/indicator`、`/reasoning`、`/fast`、`/busy`、`/verbose` 第一轮汉化。模型名、模式值保留原文。 |
| `src/app/slash/commands/ops.ts` | zh | `/browser`、`/rollback`、`/agents`、`/replay`、`/skills`、`/tools` 等第一轮汉化。工具名、路径、MCP 名保留原文。 |
| `src/components/modelPicker.tsx` | zh | 模型选择器、API key 输入、断开认证确认已汉化。provider/model ID 保留原文。 |
| `src/components/agentsOverlay.tsx` | zh | 子 Agent 树、工具调用记录、预算、文件、输出、进度、总结、操作提示已汉化。 |
| `src/lib/terminalSetup.ts` | zh | IDE 终端快捷键设置结果已汉化。 |
| `src/lib/terminalParity.ts` | zh | 终端兼容性提示已汉化。 |

### P2 低频外壳和内容补漏

| 模块 | 状态 | 说明 |
| --- | --- | --- |
| `src/app/slash/commands/debug.ts` | zh | `/heapdump`、`/mem` 输出和面板标题已汉化。 |
| `src/app/createSlashHandler.ts` | zh | 模糊命令、slash 无输出页标题已汉化。 |
| `src/app/useMainApp.ts` | zh | 网关退出、运行中状态和活动提示已汉化。 |
| `src/app/useMainApp.ts` | zh | 空闲状态不再输出 `语音 开/关`，仅保留录音/转写中的动态提示。 |
| `src/app/useConfigSync.ts` | zh | 配置变更后 MCP 自动重载提示已汉化。 |
| `src/app/createGatewayEventHandler.ts` | zh | 启动/恢复状态、目标状态、协议噪声、语音连续模式停止、命令目录不可用提示已汉化。 |
| `src/app/uiStore.ts` | zh | TUI 初始启动状态改为“正在唤起 Hermes…”。 |
| `src/app/useSubmission.ts` | zh | 运行中、加入下一轮队列、提交完成后的状态源头改为中文。 |
| `src/app/turnController.ts` | zh | 中断和恢复就绪状态源头改为中文。 |
| `src/components/appOverlays.tsx` | zh | sudo 密码提示、secret env 提示、分页帮助提示已汉化。 |
| `src/components/todoPanel.tsx` | zh | 任务面板标题和未完成提示已汉化。 |
| `src/app/setupHandoff.ts` | zh | 首次设置外部流程启动、失败、未配置 provider 提示已汉化。 |
| `src/app/useSessionLifecycle.ts` | zh | 缺少 provider 时的状态值已改为“需要设置”。 |
| `src/components/appChrome.tsx` | zh | 状态栏兼容 `setup running…` 和 `setup required` 的中文显示。 |
| `src/content/fortunes.ts` | zh | `/fortune` 本地签文已汉化。 |
| `src/content/charms.ts` | zh | 长时间工具等待提示已汉化。 |
| `src/content/verbs.ts` | zh | `terminal` 工具动词已汉化为“终端中”；思考状态词已从 `pondering` 等英文改为中文。 |
| `src/lib/text.ts` | zh | 历史/模型输出中的旧英文思考状态词会从展示预览中过滤；表情状态前缀一起清理，避免残留半截颜文字。 |
| `src/components/thinking.tsx` | zh | 子 Agent 内联委托分组兼容 `Delegate Task` 与 `委托任务`，token 单位统一为 `tokens`。 |

### 必须保留英文

- 命令和参数：例如 `/skills inspect <name>`、`/browser connect <url>`。
- 工具名、MCP server 名、provider/model ID、路径、URL、环境变量。
- 模型或工具返回的原始报错正文，避免误导排障。
- 协议枚举值：`hidden`、`collapsed`、`expanded`、`queue`、`steer` 等。

### 当前剩余风险

- `tui_gateway` 侧仍可能返回英文 `output`，TUI 只包装外层，不能随意改写原始命令输出。
- `src/__tests__` 中的可见文案断言已经同步到中文预期；后续新增文案仍要同步测试。
- 低频 overlay 和确认弹窗已做第一轮反向扫描；仍需真实交互截图验收。
- 当前 ConPTY 手工输入脚本能写入命令，但没有可靠触发 Enter；交互验收前需要先修验证器。
