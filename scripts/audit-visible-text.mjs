#!/usr/bin/env node
import fs from 'node:fs'
import { createRequire } from 'node:module'
import path from 'node:path'
import process from 'node:process'
import { fileURLToPath } from 'node:url'

let ts

const USER_TEXT_KEYS = new Set([
  'body',
  'caption',
  'content',
  'description',
  'detail',
  'error',
  'footer',
  'header',
  'help',
  'hint',
  'label',
  'message',
  'msg',
  'placeholder',
  'prompt',
  'reason',
  'rows',
  'sections',
  'status',
  'summary',
  'text',
  'title',
  'usage',
  'value'
])

const USER_TEXT_CALLS = new Set([
  'appendMessage',
  'page',
  'panel',
  'patchUiState',
  'pushActivity',
  'pushTrail',
  'setStatus',
  'sys'
])

const USER_TEXT_JSX_PROPS = new Set([
  'description',
  'label',
  'placeholder',
  'prompt',
  'title'
])

const DEFAULT_SCOPE = [
  'src/app',
  'src/components',
  'src/content',
  'src/domain',
  'src/lib',
  'src/hooks'
]

const readJson = file => JSON.parse(fs.readFileSync(file, 'utf8'))

const parseArgs = argv => {
  const args = {
    allowlist: 'allowlist/tui-visible-english.json',
    hermesRoot: 'E:/AI/hermes/hermes-agent',
    json: false,
    maxItems: 80,
    report: ''
  }

  for (let i = 0; i < argv.length; i += 1) {
    const arg = argv[i]
    if (arg === '--json') {
      args.json = true
    } else if (arg === '--hermes-root') {
      args.hermesRoot = argv[++i]
    } else if (arg === '--allowlist') {
      args.allowlist = argv[++i]
    } else if (arg === '--report') {
      args.report = argv[++i]
    } else if (arg === '--max-items') {
      args.maxItems = Number(argv[++i] ?? args.maxItems)
    } else {
      throw new Error(`unknown argument: ${arg}`)
    }
  }

  return args
}

const normalizePath = value => value.replace(/\\/g, '/')

const globToRegExp = glob => {
  let out = '^'
  for (let i = 0; i < glob.length; i += 1) {
    const ch = glob[i]
    const next = glob[i + 1]
    if (ch === '*' && next === '*') {
      out += '.*'
      i += 1
    } else if (ch === '*') {
      out += '[^/]*'
    } else if ('\\.^$+?()[]{}|'.includes(ch)) {
      out += `\\${ch}`
    } else {
      out += ch
    }
  }
  out += '$'
  return new RegExp(out)
}

const walk = dir => {
  const entries = fs.readdirSync(dir, { withFileTypes: true })
  const files = []
  for (const entry of entries) {
    const full = path.join(dir, entry.name)
    if (entry.isDirectory()) {
      files.push(...walk(full))
    } else if (/\.(ts|tsx)$/.test(entry.name)) {
      files.push(full)
    }
  }
  return files
}

const hasEnglish = text => /[A-Za-z]/.test(text)
const hasCjk = text => /[\u3400-\u9fff]/.test(text)

const nodeText = node => {
  if (ts.isStringLiteralLike(node) || node.kind === ts.SyntaxKind.NoSubstitutionTemplateLiteral) {
    return node.text
  }
  if (ts.isTemplateExpression(node)) {
    return node.head.text + node.templateSpans.map(span => `{}${span.literal.text}`).join('')
  }
  return null
}

const propertyNameText = node => {
  if (!node) return ''
  if (ts.isIdentifier(node) || ts.isStringLiteralLike(node) || ts.isNumericLiteral(node)) {
    return node.text
  }
  return node.getText()
}

const callName = expression => {
  if (ts.isIdentifier(expression)) return expression.text
  if (ts.isPropertyAccessExpression(expression)) return expression.name.text
  return expression.getText()
}

const ancestor = (node, predicate) => {
  let current = node.parent
  while (current) {
    if (predicate(current)) return current
    current = current.parent
  }
  return null
}

const isObjectValueForUserKey = node => {
  const property = node.parent
  if (!property || !ts.isPropertyAssignment(property) || property.initializer !== node) {
    return false
  }
  return USER_TEXT_KEYS.has(propertyNameText(property.name))
}

const isArrayUnderUserKey = node => {
  let current = node.parent
  while (current) {
    if (ts.isArrayLiteralExpression(current)) {
      const property = current.parent
      if (property && ts.isPropertyAssignment(property) && property.initializer === current) {
        return USER_TEXT_KEYS.has(propertyNameText(property.name))
      }
    }
    if (ts.isCallExpression(current) || ts.isFunctionLike(current)) {
      return false
    }
    current = current.parent
  }
  return false
}

const isJsxUserProp = node => {
  const attr = node.parent
  if (!attr || !ts.isJsxAttribute(attr) || !attr.initializer) {
    return false
  }
  if (attr.initializer === node) {
    return USER_TEXT_JSX_PROPS.has(attr.name.text)
  }
  if (ts.isJsxExpression(attr.initializer) && attr.initializer.expression === node) {
    return USER_TEXT_JSX_PROPS.has(attr.name.text)
  }
  return false
}

const isUserCallArgument = node => {
  const call = ancestor(node, ts.isCallExpression)
  if (!call) return false
  const name = callName(call.expression)
  if (USER_TEXT_CALLS.has(name)) return true
  if (name === 'push' || name === 'join' || name === 'map') return false
  return false
}

const isCommandDescriptor = node => {
  let current = node.parent
  while (current) {
    if (ts.isObjectLiteralExpression(current)) {
      const hasName = current.properties.some(
        prop => ts.isPropertyAssignment(prop) && propertyNameText(prop.name) === 'name'
      )
      const hasRun = current.properties.some(prop => ts.isPropertyAssignment(prop) && propertyNameText(prop.name) === 'run')
      if (hasName && hasRun) return true
    }
    current = current.parent
  }
  return false
}

const contextFor = node => {
  if (isJsxUserProp(node)) return 'jsx-prop'
  if (isObjectValueForUserKey(node)) return 'object-user-key'
  if (isArrayUnderUserKey(node)) return 'array-user-key'
  if (isUserCallArgument(node)) return 'user-call'
  if (isCommandDescriptor(node) && isObjectValueForUserKey(node)) return 'slash-command'
  return 'non-user-visible'
}

const looksMachineOnly = text => {
  const stripped = text.trim()
  if (!stripped) return true
  if (/^https?:\/\//.test(stripped)) return true
  if (/^[./\\~]?[A-Za-z0-9_.:/\\{}[\]<>?=&|%$#@!+,-]+$/.test(stripped) && !/\s/.test(stripped)) return true
  if (/^[A-Z0-9_ -]+$/.test(stripped)) return true
  if (/^[-_/\\|()[\]{}<>.:;,'"!?`~*+=#@%&$^ ]+$/.test(stripped)) return true
  if (/^#[0-9a-fA-F]{3,8}$/.test(stripped)) return true
  return false
}

const allowedReason = (text, allowlist) => {
  const stripped = text.trim()
  const exact = allowlist.allowedExact.find(item => item.text === stripped)
  if (exact) return exact.reason || 'allowed exact'
  for (const item of allowlist.allowedPatterns) {
    if (item.regex.test(stripped)) return item.reason || 'allowed pattern'
  }
  return ''
}

const forbiddenReason = (text, allowlist) => {
  for (const item of allowlist.forbiddenPatterns) {
    if (item.regex.test(text)) return item.reason || 'forbidden pattern'
  }
  return ''
}

const auditFile = (file, root, allowlist) => {
  const sourceText = fs.readFileSync(file, 'utf8')
  const source = ts.createSourceFile(file, sourceText, ts.ScriptTarget.Latest, true, file.endsWith('.tsx') ? ts.ScriptKind.TSX : ts.ScriptKind.TS)
  const findings = []
  const rel = normalizePath(path.relative(root, file))

  const visit = node => {
    const text = nodeText(node)
    if (text !== null && hasEnglish(text.trim())) {
      const trimmed = text.trim()
      const line = source.getLineAndCharacterOfPosition(node.getStart(source)).line + 1
      const context = contextFor(node)
      const forbidden = context !== 'non-user-visible' ? forbiddenReason(trimmed, allowlist) : ''
      let status = 'ignored'
      let reason = 'not in visible context'

      if (forbidden) {
        status = 'forbidden'
        reason = forbidden
      } else if (context !== 'non-user-visible') {
        if (hasCjk(trimmed)) {
          status = 'translated'
          reason = 'contains Chinese'
        } else {
          const allowed = allowedReason(trimmed, allowlist)
          if (allowed) {
            status = 'allowed'
            reason = allowed
          } else if (looksMachineOnly(trimmed)) {
            status = 'allowed'
            reason = 'machine/protocol-looking literal'
          } else {
            status = 'unapproved'
            reason = 'English prose in visible TUI context'
          }
        }
      } else {
        const allowed = allowedReason(trimmed, allowlist)
        if (allowed) {
          status = 'allowed'
          reason = allowed
        }
      }

      findings.push({ context, file: rel, line, reason, status, text: trimmed })
    }

    ts.forEachChild(node, visit)
  }

  visit(source)
  return findings
}

const summarize = findings => {
  const counts = {}
  for (const finding of findings) {
    counts[finding.status] = (counts[finding.status] ?? 0) + 1
  }
  const unapproved = findings.filter(finding => finding.status === 'unapproved' || finding.status === 'forbidden')
  const visible = findings.filter(finding => finding.context !== 'non-user-visible')
  return {
    counts: Object.fromEntries(Object.entries(counts).sort(([a], [b]) => a.localeCompare(b))),
    totalEnglishLiterals: findings.length,
    unapproved,
    unapprovedCount: unapproved.length,
    visibleEnglishLiterals: visible.length
  }
}

const toMarkdown = (summary, args, allowlistPath) => {
  const lines = [
    '# TUI 可见英文审计报告',
    '',
    `时间：${new Date().toISOString()}`,
    `HermesRoot：${args.hermesRoot}`,
    `Allowlist：${allowlistPath}`,
    '',
    '## 结果',
    '',
    `- 英文字符串总数：${summary.totalEnglishLiterals}`,
    `- 可见上下文英文字符串：${summary.visibleEnglishLiterals}`,
    `- 未批准英文：${summary.unapprovedCount}`,
    '',
    '## 分类计数',
    ''
  ]

  for (const [key, value] of Object.entries(summary.counts)) {
    lines.push(`- ${key}: ${value}`)
  }

  lines.push('', '## 未批准项', '')
  if (!summary.unapproved.length) {
    lines.push('- 无')
  } else {
    for (const item of summary.unapproved) {
      lines.push(`- ${item.file}:${item.line} [${item.context}] ${JSON.stringify(item.text)}`)
      lines.push(`  - reason: ${item.reason}`)
    }
  }

  lines.push('')
  return lines.join('\n')
}

const main = () => {
  const args = parseArgs(process.argv.slice(2))
  const hermesRoot = path.resolve(args.hermesRoot)
  const uiRoot = path.join(hermesRoot, 'ui-tui')
  const srcRoot = path.join(uiRoot, 'src')
  const projectRoot = path.resolve(path.dirname(fileURLToPath(import.meta.url)), '..')
  const allowlistPath = path.resolve(projectRoot, args.allowlist)
  const requireFromUi = createRequire(path.join(uiRoot, 'package.json'))

  ts = requireFromUi('typescript')
  const rawAllowlist = readJson(allowlistPath)
  const ignored = (rawAllowlist.ignoredFiles ?? []).map(globToRegExp)
  const allowlist = {
    allowedExact: rawAllowlist.allowedExact ?? [],
    allowedPatterns: (rawAllowlist.allowedPatterns ?? []).map(item => ({ ...item, regex: new RegExp(item.pattern) })),
    forbiddenPatterns: (rawAllowlist.forbiddenPatterns ?? []).map(item => ({ ...item, regex: new RegExp(item.pattern) }))
  }

  const files = DEFAULT_SCOPE.flatMap(scope => walk(path.join(uiRoot, scope))).filter(file => {
    const rel = normalizePath(path.relative(uiRoot, file))
    return !ignored.some(regex => regex.test(rel))
  })

  const findings = files.flatMap(file => auditFile(file, srcRoot, allowlist))
  const summary = summarize(findings)

  if (args.report) {
    const reportPath = path.resolve(args.report)
    fs.mkdirSync(path.dirname(reportPath), { recursive: true })
    fs.writeFileSync(reportPath, toMarkdown(summary, args, allowlistPath), 'utf8')
  }

  if (args.json) {
    process.stdout.write(`${JSON.stringify(summary, null, 2)}\n`)
  } else {
    console.log('TUI visible text audit')
    console.log(`HermesRoot: ${args.hermesRoot}`)
    console.log(`Allowlist: ${allowlistPath}`)
    console.log(`English literals: ${summary.totalEnglishLiterals}`)
    console.log(`Visible English literals: ${summary.visibleEnglishLiterals}`)
    console.log(`Unapproved: ${summary.unapprovedCount}`)
    for (const [key, value] of Object.entries(summary.counts)) {
      console.log(`  ${key}: ${value}`)
    }
    if (summary.unapproved.length) {
      console.log('')
      console.log('Unapproved visible English:')
      for (const item of summary.unapproved.slice(0, args.maxItems)) {
        console.log(`- ${item.file}:${item.line} [${item.context}] ${JSON.stringify(item.text)}`)
        console.log(`  reason: ${item.reason}`)
      }
    }
  }

  return summary.unapprovedCount > 0 ? 1 : 0
}

try {
  process.exitCode = main()
} catch (error) {
  console.error(error instanceof Error ? error.stack || error.message : String(error))
  process.exitCode = 1
}
