1|import { pick } from '../lib/text.js'
2|
3|export const PLACEHOLDERS = [
4|  '有什么需要帮忙的？',
5|  '试试"解释这个代码库"',
6|  '试试"帮我写一个测试"',
7|  '试试"重构 auth 模块"',
8|  '试试"/help"查看所有命令',
9|  '试试"修复 lint 错误"',
10|  '试试"config loader 是怎么工作的？"'
11|]
12|
13|export const PLACEHOLDER = pick(PLACEHOLDERS)
14|