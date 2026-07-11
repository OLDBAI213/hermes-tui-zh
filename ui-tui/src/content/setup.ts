1|import type { PanelSection } from '../types.js'
2|
3|export const SETUP_REQUIRED_TITLE = '需要配置'
4|
5|export const buildSetupRequiredSections = (): PanelSection[] => [
6|  {
7|    text: 'TUI 启动前需要先配置模型提供方。'
8|  },
9|  {
10|    rows: [
11|      ['/model', '在当前界面配置提供方和模型'],
12|      ['/setup', '在当前界面运行完整首次设置向导'],
13|      ['Ctrl+C', '退出后手动运行 `hermes setup`']
14|    ],
15|    title: '操作'
16|  }
17|]
18|