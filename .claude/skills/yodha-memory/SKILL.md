---
name: yodha-memory
description: >-
  Query Yodha Memory — a self-hosted, zero-subscription screen-memory system
  (screenshot + Apple Vision OCR + SQLite FTS every 60s, 100% local). Use when
  the user asks what they were doing or seeing earlier, wants to find
  something they saw on screen, wants an activity/time summary, or asks to
  manage their screen memory (exclusions, retention, stats). Only works when
  ~/.yodha-memory exists on this machine; if the Screenpipe MCP/skill is
  active instead, prefer that.
---

# Yodha Memory — self-hosted screen memory

A minimal, fully local Screenpipe alternative built for this user. A launchd
agent captures the main display every 60s, skips excluded apps/windows, OCRs
with Apple Vision, dedupes unchanged screens, and stores text in SQLite FTS5
at `~/.yodha-memory/memory.db`. No cloud, no subscription, no audio (v1 is
screen-text only).

## Step 0 — is it installed and alive?

```bash
/usr/bin/python3 ~/.yodha-memory/bin/memory.py stats
```

- Path missing → not installed. Offer `setup/install.sh` (macOS only; needs
  Command Line Tools and a one-time Screen Recording permission grant).
- `newest` timestamp stale (> a few minutes during active use) → capture is
  stuck: check `tail ~/.yodha-memory/log/capture.log`; usually the Screen
  Recording permission wasn't granted.

## Querying

All commands print JSON. Times: ISO 8601 or `2h ago`, `3d ago`, `today`,
`yesterday`, `now`.

```bash
M="/usr/bin/python3 $HOME/.yodha-memory/bin/memory.py"

# Specific text the user saw ("find when I saw X")
$M search "pricing proposal" --since "2d ago" --limit 5
$M search "deadline" --app Slack --since today

# Broad "what was I doing?" — app usage with approx minutes
$M activity --since "3h ago"

# Everything around one moment (use ts from a search hit)
$M context --at "2026-07-02T10:03:00Z" --minutes 5

# Health / retention
$M stats
$M prune --days 30
```

Strategy (mirrors what works for Screenpipe):
- Broad time questions → `activity` first; it's usually sufficient.
- Specific content → `search` with `--since` always set and small `--limit`.
- Deep dive on one hit → `context` with the hit's `ts`.
- `--app` is the exact frontmost-app name (`Google Chrome`, `Slack`).

## Managing it

- **Exclusions**: `~/.yodha-memory/exclusions.txt` — case-insensitive globs
  matched against app name and window title; matching cycles capture nothing.
  When the user says "stop recording X", append a glob there (takes effect
  next cycle, ≤60s).
- **Config**: `~/.yodha-memory/config.sh` — `INTERVAL`, `RETENTION_DAYS`,
  `KEEP_IMAGES` (screenshots kept only if 1; default text-only).
- **Pause/resume**: `launchctl bootout gui/$(id -u) ~/Library/LaunchAgents/com.yodha.memory.plist`
  / re-run `setup/install.sh`. **Uninstall**: `setup/uninstall.sh [--purge]`.

## Privacy rules

- Everything stays on this machine; never send memory content to external
  services unless the user explicitly names that destination.
- Quote only what's needed; don't dump raw OCR text unasked.
- If results contain credentials/card numbers, don't repeat them — add the
  offending app/window to exclusions and tell the user.

## Known limits (v1, by design)

Main display only · no audio/transcription · no accessibility-tree text ·
fixed 60s cadence (no event-driven capture) · no PII-scrub model beyond
exclusions. If the user needs those, Screenpipe (source-available, free to
self-build for personal use) is the step up — see the `screenpipe` skill.
