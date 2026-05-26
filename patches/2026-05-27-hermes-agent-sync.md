# 2026-05-27 Hermes Agent 本地同步快照

这份快照用于把当前在 `E:\AI\hermes\hermes-agent` 里做过但尚未进入独立发布包的修改，先放进本地 Git 仓 `E:\AI\github\hermes-tui-zh`，方便后续继续整理、拆包、交给 Hermes 上传或回滚核对。

## 文件

- `2026-05-27-hermes-agent-current.diff`
  - 当前 Hermes 源码仓的完整补丁快照。
  - 生成时临时把未跟踪的新文件纳入 diff，所以新建文件内容也在里面。
  - 生成后已取消临时纳入，不改变 `E:\AI\hermes\hermes-agent` 的暂存区。
- `2026-05-27-hermes-agent-diffstat.txt`
  - 补丁涉及文件和行数统计。
- `2026-05-27-hermes-agent-status.txt`
  - 生成快照后的 Hermes 源码仓状态，用于交叉核对。

## 当前覆盖范围

- 飞书汉化、显示优化、状态/工具调用显示相关改动。
- TUI 汉化、状态输出、启动警告、帮助补全验证相关改动。
- TUI 模块化、显示挂载点、诊断/模块 store 相关未发布实验文件。
- SRC 插件原型及测试文件。

## 注意

这是工作快照，不是最终发布包。后续要发布时，需要再按项目边界拆成：

- `hermes-feishu-zh`
- `hermes-feishu-display`
- `hermes-feishu-adapter`
- `hermes-tui-zh`
- `hermes-tui-skin`
- `src` / 其他插件项目

拆分前不要直接把整份 diff 当成单一项目发布。
