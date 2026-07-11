1|const FORTUNES = [
2|  '一次干净的重构，换来长久的清晰',
3|  '今天的一个好命名，省掉明天的一个大 bug',
4|  '你的下一条提交信息将无可挑剔',
5|  '你已经在脑子里解决了那个边界情况',
6|  '最小的 diff，最大的安心',
7|  '今天适合大胆删代码，而不是加新抽象',
8|  '你需要的那个工具函数，已经在代码库里了',
9|  '你会在过度思考追上来之前把功能发出去',
10|  '测试正准备拯救未来的你',
11|  '你对那个分支的直觉怀疑是对的'
12|]
13|
14|const LEGENDARY = [
15|  '传说触发：一行修复，首次成功',
16|  '传说触发：每个 flaky 测试全部通过',
17|  '传说触发：你的 diff 本身就是文档'
18|]
19|
20|const hash = (s: string) => [...s].reduce((h, c) => Math.imul(h ^ c.charCodeAt(0), 16777619), 2166136261) >>> 0
21|
22|const fromScore = (n: number) => {
23|  const rare = n % 20 === 0
24|  const bag = rare ? LEGENDARY : FORTUNES
25|
26|  return `${rare ? '🌟' : '🔮'} ${bag[n % bag.length]}`
27|}
28|
29|export const randomFortune = () => fromScore(Math.floor(Math.random() * 0x7fffffff))
30|export const dailyFortune = (seed: null | string) => fromScore(hash(`${seed || 'anon'}|${new Date().toDateString()}`))
31|