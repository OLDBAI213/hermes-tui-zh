#!/usr/bin/env python3
"""Run a multi-step Hermes TUI acceptance flow under Windows ConPTY."""

from __future__ import annotations

import argparse
import importlib.util
import json
import os
import queue
import sys
import threading
import time
from dataclasses import dataclass
from datetime import datetime
from pathlib import Path
from typing import Iterable


PROJECT_ROOT = Path(__file__).resolve().parents[1]
DEFAULT_HERMES_ROOT = Path("E:/AI/hermes/hermes-agent")
DEFAULT_FORBID_MARKERS = (
    "GatewayContext missing",
    "not TTY",
    "当前不是 TTY",
    "maximum update depth",
    "Invalid API Key",
    "Please provide valid API Key",
    "Gateway shutting down",
    "Connect browser tools",
    "List installed plugins",
    "Exit the CLI",
    "Hermes TUI Status",
    "Session ID:",
    "Agent Running:",
    "Last Activity:",
    "Tokens:",
    "Audio capture:",
    "STT provider:",
    "Audio libraries not installed",
    "Attach a local image",
    "Show current configuration",
    "Toggle the context/model",
    "Show or change the display skin",
    "Pick the TUI busy-indicator",
    "Control what Enter",
    "Manage tools",
    "List available toolsets",
    "Search, install",
    "Manage scheduled tasks",
    "Reload .env variables",
    "Show gateway/messaging",
    "Copy the last assistant",
    "Clear screen and start",
    "Force a full UI",
    "Show conversation history",
    "Save the current conversation",
)
@dataclass
class Step:
    command: str
    markers: tuple[str, ...]
    name: str
    timeout: float = 20.0


DEFAULT_STEPS = (
    Step("/help", ("快捷键",), "help panel"),
    Step("/mem", ("内存", "heap 已用"), "memory panel"),
    Step("/browser status", ("浏览器",), "browser status"),
    Step("/voice status", ("语音模式状态", "录音键"), "voice status"),
    Step("!cmd /c exit 7", ("退出码 7",), "local shell failure label"),
    Step("/status", ("Hermes TUI 状态", "会话 ID"), "status pager"),
    Step("__resize__:80x24", (), "resize to narrow viewport", timeout=5.0),
)


def load_smoke_module(hermes_root: Path):
    smoke_path = hermes_root / "scripts" / "tui_smoke_winpty.py"
    spec = importlib.util.spec_from_file_location("hermes_tui_smoke_winpty", smoke_path)
    if spec is None or spec.loader is None:
        raise RuntimeError(f"cannot load smoke harness: {smoke_path}")

    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def start_reader(proc, out: "queue.Queue[str | None]") -> threading.Thread:
    def run() -> None:
        while True:
            try:
                chunk = proc.read(4096)
            except EOFError:
                out.put(None)
                return
            except Exception as exc:
                out.put(f"\n[reader-error] {type(exc).__name__}: {exc}\n")
                out.put(None)
                return

            if chunk:
                out.put(chunk)

    thread = threading.Thread(target=run, daemon=True)
    thread.start()
    return thread


def contains_all(haystack: str, needles: Iterable[str]) -> bool:
    return all(needle and needle in haystack for needle in needles)


def drain(out: "queue.Queue[str | None]", raw_chunks: list[str], strip_ansi, seconds: float) -> str:
    deadline = time.monotonic() + max(0, seconds)

    while time.monotonic() < deadline:
        try:
            chunk = out.get(timeout=0.1)
        except queue.Empty:
            continue

        if chunk is None:
            break

        raw_chunks.append(chunk)

    return strip_ansi("".join(raw_chunks))


def wait_for_markers(
    out: "queue.Queue[str | None]",
    raw_chunks: list[str],
    strip_ansi,
    *,
    after_index: int,
    forbid_markers: tuple[str, ...],
    markers: tuple[str, ...],
    timeout: float,
) -> tuple[bool, str, list[str]]:
    deadline = time.monotonic() + timeout

    while time.monotonic() < deadline:
        try:
            chunk = out.get(timeout=0.15)
        except queue.Empty:
            sanitized = strip_ansi("".join(raw_chunks))
            window = sanitized[after_index:]
            missing = [marker for marker in markers if marker and marker not in window]

            if not missing:
                return True, sanitized, []

            continue

        if chunk is None:
            break

        raw_chunks.append(chunk)
        sanitized = strip_ansi("".join(raw_chunks))
        window = sanitized[after_index:]

        for marker in forbid_markers:
            if marker in window:
                return False, sanitized, [f"forbidden marker appeared: {marker}"]

        missing = [marker for marker in markers if marker and marker not in window]

        if not missing:
            return True, sanitized, []

    sanitized = strip_ansi("".join(raw_chunks))
    window = sanitized[after_index:]
    missing = [marker for marker in markers if marker and marker not in window]
    return False, sanitized, [f"missing marker: {marker}" for marker in missing]


def submit_command(proc, command: str, input_delay: float) -> None:
    text = command.rstrip() + " " if command.startswith("/") else command
    proc.write("\x15")
    time.sleep(min(max(0, input_delay), 0.1))
    proc.write(text)
    time.sleep(max(0, input_delay))
    proc.write("\r")


def build_isolated_env(args: argparse.Namespace, out_dir: Path) -> dict[str, str]:
    if args.use_real_hermes_home:
        return {}

    hermes_home = (args.hermes_home or (out_dir / "hermes-home")).resolve()
    workspace = (args.workspace or (out_dir / "workspace")).resolve()
    hermes_home.mkdir(parents=True, exist_ok=True)
    workspace.mkdir(parents=True, exist_ok=True)
    seed_isolated_config(hermes_home)

    return {
        "HERMES_HOME": str(hermes_home),
        "HERMES_CWD": str(workspace),
        "TERMINAL_CWD": str(workspace),
        "HERMES_TUI_ACCEPTANCE_ISOLATED": "1",
    }


def seed_isolated_config(hermes_home: Path) -> None:
    config_path = hermes_home / "config.yaml"
    if config_path.exists():
        return

    config_path.write_text(
        "\n".join(
            [
                "model:",
                "  provider: custom",
                "  default: acceptance-noop-model",
                "  base_url: http://127.0.0.1:9/v1",
                "  api_key: no-key-required",
                "agent:",
                "  image_input_mode: text",
                "display:",
                "  show_reasoning: true",
                "  mouse_tracking: true",
                "  sections:",
                "    thinking: expanded",
                "    tools: expanded",
                "",
            ]
        ),
        encoding="utf-8",
    )


def apply_env_for_spawn(values: dict[str, str]) -> dict[str, str | None]:
    saved = {key: os.environ.get(key) for key in values}
    os.environ.update(values)
    return saved


def restore_env(saved: dict[str, str | None]) -> None:
    for key, value in saved.items():
        if value is None:
            os.environ.pop(key, None)
        else:
            os.environ[key] = value


def close_proc_without_hanging(proc) -> None:
    def run() -> None:
        try:
            if proc.isalive():
                proc.sendcontrol("c")
                time.sleep(0.5)
            proc.close(force=True)
        except Exception:
            pass

    thread = threading.Thread(target=run, daemon=True)
    thread.start()
    thread.join(3.0)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Run multi-step Hermes TUI acceptance under Windows ConPTY.")
    parser.add_argument("--hermes-root", type=Path, default=DEFAULT_HERMES_ROOT)
    parser.add_argument("--cols", type=int, default=120)
    parser.add_argument("--rows", type=int, default=36)
    parser.add_argument("--startup-marker", action="append")
    parser.add_argument("--startup-timeout", type=float, default=35.0)
    parser.add_argument("--before-command-delay", type=float, default=2.5)
    parser.add_argument("--input-delay", type=float, default=0.15)
    parser.add_argument("--settle", type=float, default=0.8)
    parser.add_argument("--out-dir", type=Path)
    parser.add_argument("--hermes-home", type=Path, help="Isolated HERMES_HOME for this run. Defaults under --out-dir.")
    parser.add_argument("--workspace", type=Path, help="Isolated TERMINAL_CWD/HERMES_CWD for this run. Defaults under --out-dir.")
    parser.add_argument(
        "--use-real-hermes-home",
        action="store_true",
        help="Use the caller's current HERMES_HOME/TERMINAL_CWD. For diagnosis only; default is isolated.",
    )
    parser.add_argument("--forbid-marker", action="append", default=list(DEFAULT_FORBID_MARKERS))
    return parser.parse_args()


def main() -> int:
    args = parse_args()
    hermes_root = args.hermes_root.resolve()
    run_id = datetime.now().strftime("%Y-%m-%d-%H%M%S")
    out_dir = (args.out_dir or (PROJECT_ROOT / "tests" / "long-run-acceptance" / run_id)).resolve()
    out_dir.mkdir(parents=True, exist_ok=True)
    acceptance_env = build_isolated_env(args, out_dir)

    if not sys.platform.startswith("win"):
        print("FAIL: this acceptance harness requires native Windows ConPTY", file=sys.stderr)
        return 2

    saved_env = apply_env_for_spawn(acceptance_env)
    active_session_file = ""
    try:
        smoke = load_smoke_module(hermes_root)
        PtyProcess = smoke.import_winpty()
        argv, cwd, env, active_session_file = smoke.make_tui_process(False, False)
    finally:
        restore_env(saved_env)

    env.update(acceptance_env)
    PtyProcess = smoke.import_winpty()

    raw_chunks: list[str] = []
    out: "queue.Queue[str | None]" = queue.Queue()
    results: list[dict[str, object]] = []
    proc = None
    startup_markers = args.startup_marker or ["会话："]

    try:
      proc = PtyProcess.spawn(
          argv,
          cwd=str(cwd),
          env=env,
          dimensions=(max(8, args.rows), max(40, args.cols)),
      )
      start_reader(proc, out)

      started_at = time.monotonic()
      ok, sanitized, errors = wait_for_markers(
          out,
          raw_chunks,
          smoke.strip_ansi,
          after_index=0,
          forbid_markers=tuple(args.forbid_marker),
          markers=tuple(startup_markers),
          timeout=args.startup_timeout,
      )
      results.append(
          {
              "elapsed_seconds": round(time.monotonic() - started_at, 2),
              "errors": errors,
              "markers": startup_markers,
              "name": "startup",
              "status": "PASS" if ok else "FAIL",
          }
      )

      if not ok:
          return write_outputs(
              out_dir,
              raw_chunks,
              smoke.strip_ansi,
              results,
              argv,
              hermes_root,
              acceptance_env=acceptance_env,
              status="FAIL",
          )

      sanitized = drain(out, raw_chunks, smoke.strip_ansi, args.before_command_delay)

      for step in DEFAULT_STEPS:
          if step.command.startswith("__resize__:"):
              size = step.command.split(":", 1)[1]
              cols_text, rows_text = size.lower().split("x", 1)
              cols = int(cols_text)
              rows = int(rows_text)
              start = time.monotonic()
              resize_start = len(sanitized)
              proc.setwinsize(max(8, rows), max(40, cols))
              if step.markers:
                  ok, sanitized, errors = wait_for_markers(
                      out,
                      raw_chunks,
                      smoke.strip_ansi,
                      after_index=resize_start,
                      forbid_markers=tuple(args.forbid_marker),
                      markers=step.markers,
                      timeout=step.timeout,
                  )
              else:
                  sanitized = drain(out, raw_chunks, smoke.strip_ansi, args.settle)
                  window = sanitized[resize_start:]
                  errors = [f"forbidden marker appeared: {marker}" for marker in args.forbid_marker if marker in window]
                  ok = not errors
              results.append(
                  {
                      "command": step.command,
                      "elapsed_seconds": round(time.monotonic() - start, 2),
                      "errors": errors,
                      "markers": list(step.markers),
                      "name": step.name,
                      "status": "PASS" if ok else "FAIL",
                      "viewport": f"{cols}x{rows}",
                  }
              )
              if not ok:
                  return write_outputs(
                      out_dir,
                      raw_chunks,
                      smoke.strip_ansi,
                      results,
                      argv,
                      hermes_root,
                      acceptance_env=acceptance_env,
                      status="FAIL",
                  )
              continue

          command_start = len(sanitized)
          start = time.monotonic()
          submit_command(proc, step.command, args.input_delay)
          ok, sanitized, errors = wait_for_markers(
              out,
              raw_chunks,
              smoke.strip_ansi,
              after_index=command_start,
              forbid_markers=tuple(args.forbid_marker),
              markers=step.markers,
              timeout=step.timeout,
          )
          sanitized = drain(out, raw_chunks, smoke.strip_ansi, args.settle)
          results.append(
              {
                  "command": step.command,
                  "elapsed_seconds": round(time.monotonic() - start, 2),
                  "errors": errors,
                  "markers": list(step.markers),
                  "name": step.name,
                  "status": "PASS" if ok else "FAIL",
              }
          )

          if not ok:
              return write_outputs(
                  out_dir,
                  raw_chunks,
                  smoke.strip_ansi,
                  results,
                  argv,
                  hermes_root,
                  acceptance_env=acceptance_env,
                  status="FAIL",
              )

      status = "PASS" if all(item["status"] == "PASS" for item in results) else "FAIL"
      return write_outputs(
          out_dir,
          raw_chunks,
          smoke.strip_ansi,
          results,
          argv,
          hermes_root,
          acceptance_env=acceptance_env,
          status=status,
      )
    finally:
        if proc is not None:
            close_proc_without_hanging(proc)

        if active_session_file:
            try:
                Path(active_session_file).unlink()
            except OSError:
                pass


def write_outputs(
    out_dir: Path,
    raw_chunks: list[str],
    strip_ansi,
    results: list[dict[str, object]],
    argv: list[str],
    hermes_root: Path,
    *,
    acceptance_env: dict[str, str],
    status: str,
) -> int:
    transcript = strip_ansi("".join(raw_chunks))
    transcript_path = out_dir / "transcript.txt"
    json_path = out_dir / "results.json"
    report_path = out_dir / "long-run-acceptance.md"

    transcript_path.write_text(transcript, encoding="utf-8")
    json_path.write_text(json.dumps(results, ensure_ascii=False, indent=2), encoding="utf-8")

    lines = [
        "# Hermes TUI 长流程交互验收",
        "",
        f"时间：{datetime.now().strftime('%Y-%m-%d %H:%M:%S')}",
        f"状态：{status}",
        f"HermesRoot：{hermes_root}",
        f"隔离环境：{'否' if not acceptance_env else '是'}",
        f"命令：{' '.join(argv)}",
        "",
        "## 步骤",
        "",
        "| 步骤 | 命令 | 标记 | 状态 | 用时 |",
        "| --- | --- | --- | --- | --- |",
    ]

    for item in results:
        command = str(item.get("command", ""))
        markers = ", ".join(str(x) for x in item.get("markers", []))
        elapsed = item.get("elapsed_seconds", "")
        row_status = item.get("status", "")
        lines.append(f"| {item.get('name', '')} | `{command}` | {markers} | {row_status} | {elapsed}s |")

    errors = [error for item in results for error in item.get("errors", [])]
    lines.extend(["", "## 结论", ""])

    if status == "PASS":
        lines.extend(
            [
                "- 同一 TUI 进程内完成多条真实输入。",
                "- 覆盖 help、内存、浏览器状态、语音状态、本地 shell 错误中文标签、窄窗口 resize、状态页。",
                "- 未出现禁止标记：GatewayContext missing、not TTY、maximum update depth、Invalid API Key、Gateway shutting down。",
            ]
        )
        if acceptance_env:
            lines.append("- 验收运行在独立 HERMES_HOME 与独立工作目录，不写入真实用户会话。")
    else:
        lines.extend([f"- {error}" for error in errors] or ["- 未知失败。"])

    if acceptance_env:
        lines.extend(
            [
                "",
                "## 隔离",
                "",
                f"- HERMES_HOME：`{acceptance_env['HERMES_HOME']}`",
                f"- 工作目录：`{acceptance_env['TERMINAL_CWD']}`",
            ]
        )

    lines.extend(
        [
            "",
            "## 证据",
            "",
            f"- 终端转储：`{transcript_path}`",
            f"- 结构化结果：`{json_path}`",
        ]
    )

    report_path.write_text("\n".join(lines) + "\n", encoding="utf-8")

    print(f"Hermes TUI long-run acceptance: {status}")
    print(f"Report: {report_path}")

    return 0 if status == "PASS" else 1


if __name__ == "__main__":
    raise SystemExit(main())
