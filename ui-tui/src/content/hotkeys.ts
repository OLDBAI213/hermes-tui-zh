1|import { isMac, isRemoteShell } from '../lib/platform.js'
2|
3|const action = isMac ? 'Cmd' : 'Ctrl'
4|const paste = isMac ? 'Cmd' : 'Alt'
5|
6|const copyHotkeys: [string, string][] = isMac
7|  ? [
8|      ['Cmd+C', '复制选中内容'],
9|      ['Ctrl+C', '中断 / 清空草稿 / 退出']
10|    ]
11|  : isRemoteShell()
12|    ? [
13|        ['Cmd+C', '终端转发时复制选中内容'],
14|        ['Ctrl+C', '复制选中 / 中断 / 清空草稿 / 退出']
15|      ]
16|    : [['Ctrl+C', '复制选中 / 中断 / 清空草稿 / 退出']]
17|
18|export const HOTKEYS: [string, string][] = [
19|  ...copyHotkeys,
20|  [action + '+D', '退出'],
21|  [action + '+G / Alt+G', '打开 $EDITOR（VSCode/Cursor 下用 Alt+G）'],
22|  [action + '+L', '重绘 / 刷新'],
23|  [paste + '+V / /paste', '粘贴文本；/paste 附带剪贴板图片'],
24|  ['Tab', '应用补全'],
25|  ['↑/↓', '补全列表 / 队列编辑 / 历史记录'],
26|  ['Ctrl+X', '打开会话切换器（编辑中会删除队列消息）'],
27|  [action + '+A/E', '行首 / 行尾'],
28|  [action + '+Z / ' + action + '+Y', '撤销 / 重做输入'],
29|  [action + '+W', '删除一个单词'],
30|  [action + '+U/K', '删到行首 / 删到行尾'],
31|  [action + '+←/→', '按词跳转'],
32|  ['Home/End', '行首 / 行尾'],
33|  ['Shift+Enter / Alt+Enter', '插入换行'],
34|  ['\\+Enter', '多行续行（备用）'],
35|  ['!<命令>', '运行 shell 命令（如 !ls、!git status）'],
36|  ['{!<命令>}', '内联插入 shell 输出（如"当前分支是 {!git branch --show-current}"）']
37|]
38|