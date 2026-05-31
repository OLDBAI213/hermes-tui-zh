param(
  [string]$HermesRoot = "E:\AI\hermes\hermes-agent"
)

$ErrorActionPreference = "Stop"

function Pass($msg) { Write-Host "  [OK] $msg" -ForegroundColor Green }
function Fail($msg) { Write-Host "  [FAIL] $msg" -ForegroundColor Red; $script:Failed++ }

function Read-TextOrNull($path) {
  if (-not (Test-Path -LiteralPath $path)) { return $null }
  return Get-Content -LiteralPath $path -Raw -Encoding UTF8
}

$script:Failed = 0
$projectRoot = $PSScriptRoot
$ui = Join-Path $HermesRoot "ui-tui"
$configPath = Join-Path (Split-Path $HermesRoot -Parent) "config.yaml"

Write-Host "hermes-tui-zh local verification"
Write-Host "HermesRoot: $HermesRoot"

if (Test-Path $ui) { Pass "ui-tui exists" } else { Fail "ui-tui missing" }

if (Test-Path $configPath) {
  $configText = Get-Content -LiteralPath $configPath -Raw -Encoding UTF8
  if ($configText -match "(?m)^\s*mouse_tracking:\s*true\s*$") { Pass "display.mouse_tracking enabled for wheel scrolling" } else { Fail "display.mouse_tracking is not enabled" }
  if ($configText -match "(?m)^\s*show_reasoning:\s*true\s*$") { Pass "display.show_reasoning enabled for TUI reasoning" } else { Fail "display.show_reasoning is not enabled" }
  if ($configText -match "(?m)^\s*thinking:\s*expanded\s*$") { Pass "display.sections.thinking expanded" } else { Fail "display.sections.thinking is not expanded" }
  if ($configText -match "(?m)^\s*tools:\s*expanded\s*$") { Pass "display.sections.tools expanded" } else { Fail "display.sections.tools is not expanded" }
} else {
  Fail "Hermes config.yaml missing at $configPath"
}

$required = @(
  "src\app\useSubmission.ts",
  "src\app\useSessionLifecycle.ts",
  "src\app\runtimeFreshness.ts",
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
  "src\components\thinking.tsx",
  "src\components\queuedMessages.tsx",
  "src\__tests__\text.test.ts",
  "src\__tests__\tuiDisplayContract.test.ts",
  "src\__tests__\runtimeFreshness.test.ts",
  "src\app\slash\commands\debug.ts",
  "src\content\setup.ts",
  "src\content\placeholders.ts",
  "src\content\hotkeys.ts",
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
  @{ File = "src\content\setup.ts"; Pattern = "需要设置"; Name = "setup required copy localized" },
  @{ File = "src\content\placeholders.ts"; Pattern = "试试"; Name = "composer placeholders localized" },
  @{ File = "src\content\hotkeys.ts"; Pattern = "复制"; Name = "hotkeys localized" },
  @{ File = "src\app\useSubmission.ts"; Pattern = "会话尚未就绪"; Name = "submission session text localized" },
  @{ File = "src\app\setupHandoff.ts"; Pattern = "正在启动"; Name = "setup handoff localized" },
  @{ File = "src\app\useSessionLifecycle.ts"; Pattern = "status: '需要设置'"; Name = "setup required status localized" },
  @{ File = "src\app\runtimeFreshness.ts"; Pattern = "当前窗口仍在运行旧版本"; Name = "stale TUI runtime warning localized" },
  @{ File = "src\app\runtimeFreshness.ts"; Pattern = "endsWith('/dist/entry.js')"; Name = "stale runtime check targets bundled entry" },
  @{ File = "src\app\runtimeFreshness.ts"; Pattern = "runtimeFreshnessWarning"; Name = "stale runtime warning helper exists" },
  @{ File = "src\app\useMainApp.ts"; Pattern = "voiceLabel: voiceRecording ? '● 录音' : voiceProcessing ? '◉ 转写' : ''"; Name = "idle voice status hidden" },
  @{ File = "src\components\appOverlays.tsx"; Pattern = "需要 sudo 密码"; Name = "sudo prompt localized" },
  @{ File = "src\components\appOverlays.tsx"; Pattern = "Esc/q 关闭"; Name = "pager hint localized" },
  @{ File = "src\components\todoPanel.tsx"; Pattern = "待办"; Name = "todo panel localized" },
  @{ File = "src\app\useSessionLifecycle.ts"; Pattern = "status: '需要设置'"; Name = "session lifecycle maps setup required to Chinese" },
  @{ File = "src\app\turnController.ts"; Pattern = "已中断"; Name = "interrupt markdown localized" },
  @{ File = "src\components\appLayout.tsx"; Pattern = "Ctrl+C 中断"; Name = "composer busy placeholder localized" },
  @{ File = "src\components\messageLine.tsx"; Pattern = "工具结果为空"; Name = "empty tool result localized" },
  @{ File = "src\components\queuedMessages.tsx"; Pattern = "已排队"; Name = "queued message panel localized" },
  @{ File = "src\app\slash\commands\core.ts"; Pattern = "用法: /details"; Name = "core slash usage localized" },
  @{ File = "src\app\slash\commands\ops.ts"; Pattern = "浏览、查看、安装技能"; Name = "ops slash help localized" },
  @{ File = "src\app\slash\commands\session.ts"; Pattern = "忙碌输入模式"; Name = "session slash status localized" },
  @{ File = "src\components\agentsOverlay.tsx"; Pattern = "工具调用"; Name = "agents tool record heading localized" },
  @{ File = "src\components\modelPicker.tsx"; Pattern = "选择模型（第 2/2 步）"; Name = "model picker localized" },
  @{ File = "src\components\thinking.tsx"; Pattern = 'title="🧰 工具调用"'; Name = "tool panel title has emoji" },
  @{ File = "src\components\thinking.tsx"; Pattern = 'title="🌿 子任务树"'; Name = "subagent panel title has emoji" },
  @{ File = "src\__tests__\tuiDisplayContract.test.ts"; Pattern = "TUI display contract"; Name = "central TUI display contract test exists" },
  @{ File = "src\__tests__\tuiDisplayContract.test.ts"; Pattern = "does not expose provider English reasoning prose"; Name = "reasoning contract is regression-tested" },
  @{ File = "src\__tests__\tuiDisplayContract.test.ts"; Pattern = "renders common tool calls as Chinese UI labels"; Name = "tool display contract is regression-tested" },
  @{ File = "src\__tests__\tuiDisplayContract.test.ts"; Pattern = "browser_navigate"; Name = "browser tool context action is contract-tested" },
  @{ File = "src\__tests__\tuiDisplayContract.test.ts"; Pattern = "browser_navigate"; Name = "noisy tool context action test exists" },
  @{ File = "src\app\slash\commands\debug.ts"; Pattern = "正在写入 heap dump"; Name = "debug commands localized" },
  @{ File = "src\content\fortunes.ts"; Pattern = "传说掉落"; Name = "fortune text localized" },
  @{ File = "src\content\charms.ts"; Pattern = "还在处理中"; Name = "long-run charms localized" },
  @{ File = "src\content\verbs.ts"; Pattern = "terminal: '终端中'"; Name = "terminal verb localized" },
  @{ File = "src\content\verbs.ts"; Pattern = "'斟酌中'"; Name = "reasoning status words localized" },
  @{ File = "src\lib\text.ts"; Pattern = "import { FACES } from '../content/faces.js'"; Name = "reasoning face ticker cleanup wired" },
  @{ File = "src\lib\text.ts"; Pattern = "THINKING_FACE_PREFIX_RE"; Name = "reasoning face prefix cleanup present" },
  @{ File = "src\lib\text.ts"; Pattern = "const TOOL_EMOJIS"; Name = "tool emoji mapping present" },
  @{ File = "src\lib\text.ts"; Pattern = "toolTrailDisplayLabel"; Name = "tool calls render emoji labels" },
  @{ File = "src\lib\text.ts"; Pattern = "CONTEXT_ACTION_PREFIXES"; Name = "tool context action prefixes present" },
  @{ File = "src\lib\text.ts"; Pattern = "查看列表"; Name = "tool action context localized" },
  @{ File = "src\lib\text.ts"; Pattern = "失败原因："; Name = "failed tool details label failure reason" },
  @{ File = "src\lib\text.ts"; Pattern = "line.startsWith('模型：')"; Name = "model progress trail is transient" },
  @{ File = "src\app\createGatewayEventHandler.ts"; Pattern = "p.kind === 'model'"; Name = "model progress status handled" },
  @{ File = "src\app\createGatewayEventHandler.ts"; Pattern = "turnController.pushTrail(modelTrail)"; Name = "model progress enters tool trail" },
  @{ File = "src\app\createGatewayEventHandler.ts"; Pattern = "setStatus(p.text)"; Name = "model progress enters TUI status path" },
  @{ File = "src\app\createGatewayEventHandler.ts"; Pattern = "showSessionWarning(info.config_warning)"; Name = "session config warnings are surfaced" },
  @{ File = "src\lib\text.ts"; Pattern = "路径解析不正确，正在修正路径并重试"; Name = "English reasoning is summarized in Chinese" },
  @{ File = "src\lib\terminalSetup.ts"; Pattern = "终端快捷键"; Name = "terminal setup localized" },
  @{ File = "src\lib\terminalParity.ts"; Pattern = "检测到"; Name = "terminal parity hints localized" }
)

foreach ($check in $checks) {
  $path = Join-Path $ui $check.File
  $text = Read-TextOrNull $path
  if ($null -eq $text) {
    Fail "$($check.Name) (missing file: $($check.File))"
    continue
  }
  if ($text.Contains($check.Pattern)) { Pass $check.Name } else { Fail $check.Name }
}

$backendChecks = @(
  @{ File = "agent\status_events.py"; Pattern = 'getattr(agent, "platform", "") != "tui"'; Name = "model progress is TUI-only at source" },
  @{ File = "agent\chat_completion_helpers.py"; Pattern = "emit_tui_model_status"; Name = "backend emits TUI-scoped model progress status" },
  @{ File = "agent\chat_completion_helpers.py"; Pattern = "emit_tui_model_status"; Name = "backend emits TUI-scoped model wait heartbeat" },
  @{ File = "gateway\run.py"; Pattern = 'event_type_normalized == "model"'; Name = "gateway suppresses TUI-only model status" },
  @{ File = "tui_gateway\entry.py"; Pattern = "_start_mcp_discovery_background"; Name = "TUI MCP discovery is scheduled after gateway ready" },
  @{ File = "tui_gateway\entry.py"; Pattern = "server.refresh_mcp_tools_for_sessions()"; Name = "background MCP discovery refreshes live TUI sessions" },
  @{ File = "tui_gateway\server.py"; Pattern = "refresh_mcp_tools_for_sessions"; Name = "TUI MCP refresh waits for agent readiness" },
  @{ File = "tui_gateway\server.py"; Pattern = "TUI 思考显示当前关闭"; Name = "gateway warns when TUI reasoning is disabled" },
  @{ File = "tui_gateway\server.py"; Pattern = "工具调用面板会被隐藏"; Name = "gateway warns when tool panel is hidden" },
  @{ File = "tui_gateway\server.py"; Pattern = "连接或查看 Chromium 系浏览器 CDP 工具"; Name = "TUI command catalog browser description localized" },
  @{ File = "tui_gateway\server.py"; Pattern = "列出已安装插件及状态"; Name = "TUI command catalog plugins description localized" },
  @{ File = "tui_gateway\server.py"; Pattern = "Hermes TUI 状态"; Name = "TUI session status output localized" },
  @{ File = "tui_gateway\server.py"; Pattern = "显示或切换显示皮肤/主题"; Name = "TUI CLI-only command descriptions localized" },
  @{ File = "model_tools.py"; Pattern = "_filter_redundant_native_vision_tools"; Name = "native multimodal hides redundant vision tool" },
  @{ File = "model_tools.py"; Pattern = "HERMES_KEEP_VISION_ANALYZE_TOOL"; Name = "vision tool escape hatch is explicit" },
  @{ File = "tools\vision_tools.py"; Pattern = "built-in vision"; Name = "vision schema tells native model to answer directly" },
  @{ File = "agent\image_routing.py"; Pattern = "main model's native vision wins"; Name = "native image routing beats stale aux vision" },
  @{ File = "agent\models_dev.py"; Pattern = 'model in {"mimo-v2.5", "mimo-v2-omni"}'; Name = "MiMo image-understanding models marked vision-capable" },
  @{ File = "run_agent.py"; Pattern = "def refresh_tools"; Name = "AIAgent can refresh dynamic tool surface" },
  @{ File = "run_agent.py"; Pattern = "HERMES_BACKGROUND_REVIEW_DELAY_SECONDS"; Name = "TUI background review delay gate present" },
  @{ File = "run_agent.py"; Pattern = "new foreground TUI turn started"; Name = "TUI background review skips when foreground resumes" }
)

foreach ($check in $backendChecks) {
  $path = Join-Path $HermesRoot $check.File
  $text = Read-TextOrNull $path
  if ($null -eq $text) {
    Fail "$($check.Name) (missing file: $($check.File))"
    continue
  }
  if ($text.Contains($check.Pattern)) { Pass $check.Name } else { Fail $check.Name }
}

$scriptChecks = @(
  @{ File = "tests\agent\test_status_events.py"; Pattern = "test_emit_tui_model_status_only_for_tui"; Name = "model progress source guard test exists" },
  @{ File = "tests\gateway\test_feishu_zh_progress.py"; Pattern = "test_gateway_model_status_is_tui_only_not_platform_message"; Name = "gateway model status suppression test exists" },
  @{ File = "tests\test_tui_display_contract.py"; Pattern = "test_tui_session_info_surfaces_display_health"; Name = "backend TUI display contract test exists" },
  @{ File = "tests\tui_gateway\test_entry_startup.py"; Pattern = "test_entry_emits_ready_before_scheduling_mcp"; Name = "gateway ready before MCP scheduling test exists" },
  @{ File = "tests\test_tui_gateway_server.py"; Pattern = "test_refresh_mcp_tools_refreshes_ready_sessions"; Name = "live MCP tool refresh test exists" },
  @{ File = "tests\test_tui_gateway_server.py"; Pattern = "test_refresh_mcp_tools_waits_for_agent_readiness"; Name = "MCP refresh readiness test exists" },
  @{ File = "tests\test_model_tools.py"; Pattern = "test_hides_vision_analyze_when_main_model_is_native"; Name = "native multimodal tool hiding test exists" },
  @{ File = "tests\test_model_tools.py"; Pattern = "test_quiet_cache_key_changes_when_native_image_routing_changes"; Name = "tool cache native routing guard test exists" },
  @{ File = "tests\agent\test_image_routing.py"; Pattern = "test_xiaomi_keeps_nested_openai_image_url_shape"; Name = "MiMo native image shape test exists" },
  @{ File = "tests\agent\test_models_dev.py"; Pattern = "test_xiaomi_mimo_v2_omni_is_forced_vision_capable"; Name = "MiMo Omni vision capability test exists" },
  @{ File = "tests\tools\test_vision_tools.py"; Pattern = "test_check_requirements_accepts_native_main_model_without_aux_key"; Name = "native vision status guard test exists" },
  @{ File = "tests\test_tui_gateway_server.py"; Pattern = "test_tui_does_not_force_text_mode_for_xiaomi_mimo"; Name = "TUI MiMo does not force text image mode" },
  @{ File = "scripts\tui_smoke_winpty.py"; Pattern = "--slash-command"; Name = "ConPTY smoke supports slash command submission" },
  @{ File = "scripts\tui_smoke_winpty.py"; Pattern = "--before-input-delay"; Name = "ConPTY smoke can wait before input" },
  @{ File = "scripts\tui_smoke_winpty.py"; Pattern = 'rstrip() + " "'; Name = "slash command avoids completion enter trap" },
  @{ File = "tests\tui_gateway\test_protocol.py"; Pattern = "Connect browser tools"; Name = "command catalog dynamic English regression test exists" },
  @{ File = "tests\test_tui_gateway_server.py"; Pattern = "Hermes TUI 状态"; Name = "session status Chinese regression test exists" }
)

foreach ($check in $scriptChecks) {
  $path = Join-Path $HermesRoot $check.File
  $text = Read-TextOrNull $path
  if ($null -eq $text) {
    Fail "$($check.Name) (missing file: $($check.File))"
    continue
  }
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
  "caps d",
  "模型返回英文思考",
  "英文原文（模型返回，不是错误）"
)

$projectChecks = @(
  @{ File = "scripts\tui-long-run-acceptance.py"; Pattern = "DEFAULT_FORBID_MARKERS"; Name = "long-run TUI acceptance harness exists" },
  @{ File = "scripts\tui-long-run-acceptance.py"; Pattern = "Connect browser tools"; Name = "long-run command catalog English forbid exists" },
  @{ File = "scripts\tui-long-run-acceptance.py"; Pattern = "Audio capture:"; Name = "long-run voice English forbid exists" },
  @{ File = "scripts\tui-long-run-acceptance.py"; Pattern = "build_isolated_env"; Name = "long-run acceptance isolates Hermes home by default" },
  @{ File = "scripts\tui-long-run-acceptance.py"; Pattern = "--use-real-hermes-home"; Name = "long-run real home requires explicit flag" },
  @{ File = "scripts\tui-long-run-acceptance.py"; Pattern = "seed_isolated_config"; Name = "long-run isolated test config is seeded" }
)

foreach ($check in $projectChecks) {
  $path = Join-Path $projectRoot $check.File
  $text = Read-TextOrNull $path
  if ($null -eq $text) {
    Fail "$($check.Name) (missing file: $($check.File))"
    continue
  }
  if ($text.Contains($check.Pattern)) { Pass $check.Name } else { Fail $check.Name }
}

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
  "src\components\thinking.tsx",
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
    $text = Read-TextOrNull $path
    if ($null -eq $text) { continue }
    if ($text.Contains($pattern)) { $hits += $rel }
  }

  if ($hits.Count -eq 0) { Pass "legacy text removed: $pattern" } else { Fail "legacy text still present: $pattern in $($hits -join ', ')" }
}

$auditScript = Join-Path $projectRoot "scripts\audit-visible-text.mjs"
$auditReport = Join-Path $projectRoot "tests\visible-text-report.md"

if (Test-Path -LiteralPath $auditScript) {
  try {
    $auditOutput = & node $auditScript --hermes-root $HermesRoot --report $auditReport --max-items 80 2>&1

    if ($LASTEXITCODE -eq 0) {
      Pass "TUI visible English audit passed"
    } else {
      Fail "TUI visible English audit failed (report: $auditReport)"
      $auditOutput | Select-Object -First 40 | ForEach-Object {
        Write-Host "    $_" -ForegroundColor DarkYellow
      }
    }
  } catch {
    Fail "TUI visible English audit crashed: $($_.Exception.Message)"
  }
} else {
  Fail "TUI visible English audit script missing"
}

Write-Host ""
Write-Host "SUMMARY"
Write-Host "  Failed: $Failed"

if ($Failed -gt 0) { exit 1 }
