param(
  [string]$HermesRoot = "E:\AI\hermes\hermes-agent"
)

$ErrorActionPreference = "Stop"

function Pass($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Fail($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red; $script:Failed++ }

$script:Failed = 0
$ui = Join-Path $HermesRoot "ui-tui"
$configPath = Join-Path (Split-Path $HermesRoot -Parent) "config.yaml"

Write-Host "hermes-tui-zh local verification"
Write-Host "HermesRoot: $HermesRoot"

if (Test-Path $ui) { Pass "ui-tui exists" } else { Fail "ui-tui missing" }

if (Test-Path $configPath) {
  $configText = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
  if ($configText -match "(?m)^\s*mouse_tracking:\s*true\s*$") { Pass "display.mouse_tracking enabled for wheel scrolling" } else { Fail "display.mouse_tracking is not enabled" }
} else {
  Fail "Hermes config.yaml missing at $configPath"
}

$required = @(
  "src\content\zh.ts",
  "src\app\useSubmission.ts",
  "src\app\useSessionLifecycle.ts",
  "src\app\setupHandoff.ts",
  "src\app\turnController.ts",
  "src\app\slash\commands\core.ts",
  "src\app\slash\commands\ops.ts",
  "src\app\slash\commands\session.ts",
  "src\components\messageLine.tsx",
  "src\components\appLayout.tsx",
  "src\components\appOverlays.tsx",
  "src\components\appChrome.tsx",
  "src\components\todoPanel.tsx",
  "src\components\agentsOverlay.tsx",
  "src\components\modelPicker.tsx",
  "src\app\slash\commands\debug.ts",
  "src\content\fortunes.ts",
  "src\content\charms.ts",
  "src\content\verbs.ts",
  "src\lib\text.ts",
  "src\lib\terminalSetup.ts",
  "src\lib\terminalParity.ts"
)

foreach ($rel in $required) {
  $path = Join-Path $ui $rel
  if (Test-Path $path) { Pass "$rel exists" } else { Fail "$rel missing" }
}

$checks = @(
  @{ File = "src\content\zh.ts"; Pattern = "会话尚未就绪"; Name = "session-not-ready Chinese string" },
  @{ File = "src\content\zh.ts"; Pattern = "已加入队列"; Name = "queued Chinese string" },
  @{ File = "src\content\zh.ts"; Pattern = "已中断"; Name = "interrupted Chinese string" },
  @{ File = "src\content\zh.ts"; Pattern = "工具结果为空"; Name = "empty tool result Chinese string" },
  @{ File = "src\app\useSubmission.ts"; Pattern = "ZH.sessionNotReady"; Name = "submission uses zh session text" },
  @{ File = "src\app\setupHandoff.ts"; Pattern = "正在启动"; Name = "setup handoff localized" },
  @{ File = "src\app\useSessionLifecycle.ts"; Pattern = "status: '需要设置'"; Name = "setup required status localized" },
  @{ File = "src\app\useMainApp.ts"; Pattern = "voiceLabel: voiceRecording ? '● 录音' : voiceProcessing ? '◉ 转写' : ''"; Name = "idle voice status hidden" },
  @{ File = "src\components\appOverlays.tsx"; Pattern = "需要 sudo 密码"; Name = "sudo prompt localized" },
  @{ File = "src\components\appOverlays.tsx"; Pattern = "Esc/q 关闭"; Name = "pager hint localized" },
  @{ File = "src\components\todoPanel.tsx"; Pattern = "待办"; Name = "todo panel localized" },
  @{ File = "src\components\appChrome.tsx"; Pattern = "'setup required': '需要设置'"; Name = "status bar maps setup required to Chinese" },
  @{ File = "src\app\turnController.ts"; Pattern = "ZH.interruptedMarkdown"; Name = "interrupt markdown localized" },
  @{ File = "src\components\appLayout.tsx"; Pattern = "Ctrl+C 中断"; Name = "composer busy placeholder localized" },
  @{ File = "src\components\messageLine.tsx"; Pattern = "ZH.emptyToolResult"; Name = "empty tool result localized" },
  @{ File = "src\app\slash\commands\core.ts"; Pattern = "用法: /details"; Name = "core slash usage localized" },
  @{ File = "src\app\slash\commands\ops.ts"; Pattern = "浏览、查看、安装技能"; Name = "ops slash help localized" },
  @{ File = "src\app\slash\commands\session.ts"; Pattern = "忙碌输入模式"; Name = "session slash status localized" },
  @{ File = "src\components\agentsOverlay.tsx"; Pattern = "🛠 工具调用记录"; Name = "agents tool record heading localized" },
  @{ File = "src\components\modelPicker.tsx"; Pattern = "选择模型（第 2/2 步）"; Name = "model picker localized" },
  @{ File = "src\app\slash\commands\debug.ts"; Pattern = "正在写入 heap dump"; Name = "debug commands localized" },
  @{ File = "src\content\fortunes.ts"; Pattern = "传说掉落"; Name = "fortune text localized" },
  @{ File = "src\content\charms.ts"; Pattern = "还在处理中"; Name = "long-run charms localized" },
  @{ File = "src\content\verbs.ts"; Pattern = "terminal: '终端中'"; Name = "terminal verb localized" },
  @{ File = "src\content\verbs.ts"; Pattern = "'斟酌中'"; Name = "reasoning status words localized" },
  @{ File = "src\lib\text.ts"; Pattern = "import { FACES } from '../content/faces.js'"; Name = "reasoning face ticker cleanup wired" },
  @{ File = "src\lib\text.ts"; Pattern = "THINKING_FACE_PREFIX_RE"; Name = "reasoning face prefix cleanup present" },
  @{ File = "src\lib\terminalSetup.ts"; Pattern = "终端快捷键"; Name = "terminal setup localized" },
  @{ File = "src\lib\terminalParity.ts"; Pattern = "检测到"; Name = "terminal parity hints localized" }
)

foreach ($check in $checks) {
  $path = Join-Path $ui $check.File
  $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
  if ($text.Contains($check.Pattern)) { Pass $check.Name } else { Fail $check.Name }
}

$legacyPatterns = @(
  "session not ready yet",
  "error: invalid response: shell.exec",
  "steer failed — message queued for next turn",
  "*[interrupted]*",
  "(empty tool result)",
  "Ctrl+C to interrupt",
  "No image found in clipboard",
  "voice error:",
  "failed to open editor",
  "usage: /details",
  "skill commands available",
  "set global agent detail visibility mode",
  "override one section",
  "show a random or daily local fortune",
  "mouse tracking on",
  "mouse tracking off",
  "clipboard copy failed",
  "copy failed:",
  "terminal setup failed:",
  "restart the IDE terminal",
  "tool calls)",
  "conversation saved to:",
  "queued message(s)",
  "no active turn",
  "steer queued",
  "undid ",
  "browser not connected",
  "Rollback checkpoints",
  "Rollback diff",
  "No subagents this turn",
  "Replay diff",
  "baseline vs candidate",
  "Tool calls",
  "Select provider",
  "Select model",
  "loading models",
  "no providers available",
  "Paste your API key",
  "failed to save key",
  "terminal setup must be run",
  "No supported IDE terminal detected",
  "startup query skipped",
  "startup image attach failed",
  "gateway startup timeout",
  '语音 ${voiceEnabled',
  "sudo password required",
  "Enter/Space/PgDn page",
  "Esc/q close",
  "incomplete ·",
  "still pending",
  "pending/in_progress",
  "approval needed",
  "sudo password needed",
  "secret input needed",
  "setup required",
  "setup running",
  "launching `hermes",
  "error launching hermes",
  "still no provider configured",
  "ambiguous command:",
  ": no output",
  "gateway exited",
  "writing heap dump",
  "heapdump failed:",
  "print live V8 heap",
  "write a V8 heap snapshot",
  "heap used",
  "still cooking",
  "polishing edges",
  "asking the void",
  "pondering",
  "contemplating",
  "cogitating",
  "ruminating",
  "deliberating",
  "brainstorming",
  "legendary drop",
  "minimal diff",
  "you are one clean refactor",
  "terminal: 'terminal'",
  "caps d"
)

$scanFiles = @(
  "src\app\useSubmission.ts",
  "src\app\useSessionLifecycle.ts",
  "src\app\turnController.ts",
  "src\app\useMainApp.ts",
  "src\app\useInputHandlers.ts",
  "src\app\setupHandoff.ts",
  "src\app\createGatewayEventHandler.ts",
  "src\app\slash\commands\core.ts",
  "src\app\slash\commands\ops.ts",
  "src\app\slash\commands\session.ts",
  "src\components\messageLine.tsx",
  "src\components\appLayout.tsx",
  "src\components\appOverlays.tsx",
  "src\components\todoPanel.tsx",
  "src\components\agentsOverlay.tsx",
  "src\components\modelPicker.tsx",
  "src\app\slash\commands\debug.ts",
  "src\content\fortunes.ts",
  "src\content\charms.ts",
  "src\content\verbs.ts",
  "src\lib\terminalSetup.ts",
  "src\lib\terminalParity.ts"
)

foreach ($pattern in $legacyPatterns) {
  $hits = @()
  foreach ($rel in $scanFiles) {
    $path = Join-Path $ui $rel
    $text = Get-Content -LiteralPath $path -Raw -Encoding UTF8
    if ($text.Contains($pattern)) { $hits += $rel }
  }

  if ($hits.Count -eq 0) { Pass "legacy text removed: $pattern" } else { Fail "legacy text still present: $pattern in $($hits -join ', ')" }
}

Write-Host ""
Write-Host "SUMMARY"
Write-Host "  Failed: $Failed"

if ($Failed -gt 0) { exit 1 }
