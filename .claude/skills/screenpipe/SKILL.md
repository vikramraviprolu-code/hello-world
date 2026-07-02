---
name: screenpipe
description: >-
  Query and automate Screenpipe — the local-first screen/audio recorder that
  gives AI agents memory of what the user saw, said, and did. Use when the
  user asks about their past activity ("what was I doing", "what did I discuss
  in that meeting", "find when I saw X"), wants a summary of their day/meetings,
  wants to search their screen or audio history, or wants to create a pipe
  (scheduled AI automation) or persistent memory. Requires the Screenpipe app
  running locally on the user's machine.
---

# Screenpipe — workflow memory for this machine

Screenpipe (screenpipe.com) runs locally and records screen text
(accessibility tree + OCR fallback), audio transcriptions (local Whisper),
input events, and detected meetings into a SQLite database at
`~/.screenpipe/db.sqlite`. It exposes a REST API on `http://localhost:3030`.
This skill teaches you to query that API directly and to author pipes.

## Step 0 — check it's running

```bash
.claude/skills/screenpipe/scripts/sp.sh health
```

If this fails, Screenpipe isn't running (or isn't installed) — tell the user
to start the desktop app or run `screenpipe` in a terminal, and stop there.
If the API returns 401/403, an API key is required: ask the user to set
`SCREENPIPE_LOCAL_API_KEY` (the script sends it as a Bearer token).

Note: if the `screenpipe` MCP server is connected in this session, prefer its
tools (`search-content`, `activity-summary`, `list-meetings`, `create-pipe`, …)
over raw HTTP — same backend, richer ergonomics. This skill is the fallback
when only the REST API is reachable, and the reference for pipe authoring.

## Query strategy — start light, escalate only when needed

1. **Broad "what was I doing?" questions** → `GET /activity-summary` with a
   time range. Pre-summarizes apps, windows, durations, transcripts. Almost
   always the right first call; let it own all time math — never sum minutes
   yourself.
2. **Specific text / quotes / transcript lines** → `GET /search`.
3. **Specific UI controls or page structure** → element search.
4. **Full detail on one moment** → `GET /frames/{frame_id}/context` using a
   `frame_id` from search results.

Hard-won rules (from Screenpipe's own agent guide):
- **Always pass `start_time`** — omitting it scans the entire history.
- **Start with `limit=5`**, increase only if needed.
- **Don't pass `q` when searching audio** — transcriptions are noisy and `q`
  filters too aggressively; filter by time range and speaker instead.
- `app_name` is **case-sensitive** and exact: `Google Chrome`, not `chrome`.
- `content_type=ocr` means *all screen text* (accessibility-derived for most
  apps, OCR only as fallback) — don't over-filter.
- Times accept ISO 8601 UTC or relative forms: `2h ago`, `1d ago`, `today`,
  `yesterday`, `now`.

The helper script wraps the common calls:

```bash
scripts/sp.sh activity "3h ago" now              # activity summary
scripts/sp.sh search "project deadline" --type ocr --since "1d ago" --limit 5
scripts/sp.sh meetings --since "1w ago"          # detected meetings
scripts/sp.sh raw "/search?content_type=audio&start_time=2h%20ago&limit=5"
```

Full endpoint and parameter reference: `reference/api.md`.

## Pipes — scheduled AI automations

A pipe is a folder `~/.screenpipe/pipes/<name>/` containing `pipe.md`
(YAML frontmatter with a `schedule`, plus a markdown prompt an AI agent runs
each execution). Screenpipe prepends time range, timezone, and API
credentials to every run, so prompts need no template variables.

When the user asks to automate something recurring ("summarize my day at
6pm", "log my AI prompts to Obsidian"), read `reference/pipes.md` first —
it documents the exact frontmatter, schedule syntax, permission fields
(`allow-apps`, `deny-windows`, `allow-raw-sql`, …), and prompt-writing rules.
Keep each pipe to one bounded job.

## Memories

Screenpipe stores persistent facts ("memories") the user wants remembered.
Retrieve with `GET /search?content_type=memory&q=...`; prefer namespaced tags
(`person:ada`, `project:atlas`, `topic:pricing`) which link memories to tagged
frames/audio.

## Privacy rules for this skill

- Results can contain anything the user saw or said, including other people's
  words. Quote only what's needed to answer; don't dump raw transcripts
  unasked.
- Never send Screenpipe content to external services (web, email, cloud APIs)
  without the user explicitly asking for that destination.
- If results include obvious credentials or card numbers the scrubber missed,
  don't repeat them — tell the user to add that app/window to exclusions.
