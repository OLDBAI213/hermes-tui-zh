# 交互验证记录

日期：2026-05-25

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
