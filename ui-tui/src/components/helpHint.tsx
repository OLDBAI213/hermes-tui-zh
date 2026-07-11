1|import { Box, Text } from '@hermes/ink'
2|
3|import { HOTKEYS } from '../content/hotkeys.js'
4|import type { Theme } from '../theme.js'
5|
6|const COMMON_COMMANDS: [string, string][] = [
7|  ['/help', '命令与快捷键完整列表'],
8|  ['/clear', '开始新会话'],
9|  ['/resume', '切换或恢复历史会话'],
10|  ['/details', '控制消息详情级别'],
11|  ['/copy', '复制选中内容或最后一条回复'],
12|  ['/quit', '退出 Hermes']
13|]
14|
15|const HOTKEY_PREVIEW = HOTKEYS.slice(0, 8)
16|
17|export function HelpHint({ t }: { t: Theme }) {
18|  const labelW = Math.max(...COMMON_COMMANDS.map(([k]) => k.length), ...HOTKEY_PREVIEW.map(([k]) => k.length))
19|
20|  const pad = (s: string) => s + ' '.repeat(Math.max(0, labelW - s.length + 2))
21|
22|  return (
23|    <Box alignItems="flex-start" bottom="100%" flexDirection="column" left={0} position="absolute" right={0}>
24|      <Box
25|        alignSelf="flex-start"
26|        borderColor={t.color.primary}
27|        borderStyle="round"
28|        flexDirection="column"
29|        marginBottom={1}
30|        opaque
31|        paddingX={1}
32|      >
33|        <Text>
34|          <Text bold color={t.color.primary}>
35|            ? 快速帮助
36|          </Text>
37|          <Text color={t.color.muted}>{'  ·  输入 /help 查看完整面板  ·  退格键关闭'}</Text>
38|        </Text>
39|
40|        <Box marginTop={1}>
41|          <Text bold color={t.color.accent}>
42|            常用命令
43|          </Text>
44|        </Box>
45|
46|        {COMMON_COMMANDS.map(([k, v]) => (
47|          <Text key={k}>
48|            <Text color={t.color.label}>{pad(k)}</Text>
49|            <Text color={t.color.muted}>{v}</Text>
50|          </Text>
51|        ))}
52|
53|        <Box marginTop={1}>
54|          <Text bold color={t.color.accent}>
55|            快捷键
56|          </Text>
57|        </Box>
58|
59|        {HOTKEY_PREVIEW.map(([k, v]) => (
60|          <Text key={k}>
61|            <Text color={t.color.label}>{pad(k)}</Text>
62|            <Text color={t.color.muted}>{v}</Text>
63|          </Text>
64|        ))}
65|      </Box>
66|    </Box>
67|  )
68|}
69|