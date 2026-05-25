# TUI 汉化预检与返工防线

## 目标

在 Hermes 原生 TUI 上做中文化，不重写 TUI，不改变主布局，不删原有信息。先建立清单和验收，再改字符串。

## 飞书阶段教训

1. 不能只按截图修。截图只能证明一个页面有问题，不能证明其他模块没问题。
2. 不能只查自己改过的地方。验收要反向找英文、找硬编码、找未覆盖事件。
3. 不能为了美观删信息。信息必须保留，只能换布局、缩短、折叠或按需显示。
4. 不能把本机配置当项目要求。本机模型、路径、端口只写在验收记录，不写成安装前提。
5. 不能说“检查好了”但没有可重复证据。每次结论必须对应脚本、测试、截图或运行日志。
6. 同一问题第二次出现，先补验收规则，再继续修代码。

## 受保护区域

- 主聊天 transcript。
- composer 输入框和粘贴流程。
- slash 补全菜单。
- JSON-RPC 事件流。
- 网关启动、会话恢复、工具调用状态。

这些区域可以汉化文案，但不能重排核心交互，除非先有单独方案和可视验收。

## 汉化范围

### P0 主流程

- 启动、连接、退出、重启、错误。
- 输入占位、提交、队列、忙碌、取消。
- 思考、工具调用、工具结果、失败、耗时。
- 会话、模型、状态栏、复制粘贴、图片粘贴。
- slash 命令反馈。

### P1 功能面板

- 模型选择器。
- 会话选择器。
- 子任务/agents overlay。
- 终端适配提示。
- todo、计划、diff、编辑器提示。

### P2 边缘状态

- 远程终端、tmux、Termux、Cursor/VS Code 终端提示。
- gateway attach/sidecar 错误。
- dashboard 嵌入 TUI 的提示。
- 录制、截图、浏览器、语音、审批、secret/sudo/clarify。

## 不能汉化的内容

- 命令名、工具名、文件路径、API 名、模型名。
- 用户输入和模型原始回答。
- 代码、diff、日志里的原始错误。
- 需要和上游协议一致的字段值。

这些内容可加中文解释，但原文必须保留。

## 审查方法

1. 扫描 `ui-tui/src` 所有 `.ts/.tsx` 字符串。
2. 按模块分组，不按截图分组。
3. 每个英文字符串标记为：要汉化、保留原文、需要中文解释、测试内容、代码注释。
4. 先补 `content/zh.ts` 或集中映射，少量无法抽取的再就地改。
5. 每个改动都要有测试或 smoke 入口。

## 最小验证链

```powershell
cd E:\AI\hermes\hermes-agent\ui-tui
npm run type-check
npm test -- src/__tests__/reasoning.test.ts src/__tests__/prompt.test.ts src/__tests__/slashParity.test.ts
```

```powershell
cd E:\AI\hermes\hermes-agent
uv run python -m pytest -n0 --timeout-method=thread tests\hermes_cli\test_tui_display_defaults.py
```

真实可视验收必须至少覆盖：

- 80 列窄窗口。
- 120 列普通窗口。
- 有思考内容。
- 有工具调用。
- 有失败工具。
- slash 命令反馈。

## 停止条件

- 改动影响 composer、transcript、completion、gateway event 但没有测试。
- 新增布局导致输入行、补全菜单、消息内容被遮挡。
- 英文扫描发现 P0/P1 还有明显漏项却声称完成。
- 同一问题第三次出现，停止写代码，先改验证脚本。
