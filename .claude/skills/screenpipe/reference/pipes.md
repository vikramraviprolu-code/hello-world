# Authoring pipes — scheduled AI automations

A pipe is a markdown prompt an AI agent executes on a schedule. Each pipe is
a folder `~/.screenpipe/pipes/<name>/` containing `pipe.md`. Name pipes in
kebab-case (`daily-time-report`).

## pipe.md anatomy

```markdown
---
schedule: every day at 9am
enabled: true
preset: ["Primary", "Fallback"]   # optional AI model preset(s); omit for default
history: false                     # feed prior run's output back in next run
---

Your instructions here. This prompt is what the AI agent executes on schedule.
```

`schedule` (required): `every 30m` · `every 1h` · `every day at 9am` ·
`every monday at 9am` · or cron (`0 9 * * *`).

Screenpipe **prepends a context header** to every run — current time range,
timezone, OS, API base URL + auth key. Prompts need no template variables and
must never hardcode credentials.

## Data-permission frontmatter (optional, enterprise-grade control)

Deterministic OS-level limits on what the pipe's agent can access — enforced
by skill gating, agent interception, and server middleware (per-pipe tokens),
not by prompting:

| Field | Meaning |
|---|---|
| `allow-apps` / `deny-apps` | Glob patterns on app names |
| `deny-windows` | Glob patterns on window titles |
| `allow-content-types` | Restrict to `ocr`, `audio`, `input`, `accessibility` |
| `time-range` | e.g. `09:00-18:00` |
| `days` | e.g. `Mon,Tue,Wed,Thu,Fri` |
| `allow-raw-sql` | default should be `false` |
| `allow-frames` | gate screenshot access |

When writing a pipe for a user, default to the narrowest grants that still do
the job (e.g. a standup pipe needs work hours + work apps only).

## Writing a good pipe prompt

One bounded job per pipe. The prompt should concretely do three things:

1. **Query** — name the endpoints and time range:
   - `GET /activity-summary?start_time=...&end_time=now` for apps/durations.
     Let this endpoint own all time math; never have the model sum minutes.
   - `GET /search?q=...&content_type=...&start_time=...` for specific text,
     transcripts, memories. Always pass `start_time`.
   - `GET /meetings?...` for meetings.
2. **Process** — how to summarize/transform.
3. **Output** — exactly one destination: write a file/note, desktop
   notification (`POST localhost:11435/notify`), or a configured connection
   (Slack/Telegram/Email/Notion…).

## Lifecycle

1. Write `~/.screenpipe/pipes/<name>/pipe.md` (or use MCP `create-pipe`,
   which writes + installs + enables + test-runs it).
2. Test-run it once immediately (MCP `run-pipe`, or wait for schedule).
3. Read the logs (MCP `pipe-logs`) to confirm the run did what was intended.
4. Change config later via `POST /pipes/<name>/config`
   with `{ "schedule": "every 1h", "enabled": true }`.

Never mark a pipe done without checking its test-run logs.

## Example

`~/.screenpipe/pipes/daily-time-report/pipe.md`:

```markdown
---
schedule: every day at 6pm
enabled: true
time-range: 08:00-19:00
days: Mon,Tue,Wed,Thu,Fri
allow-raw-sql: false
---

Call GET /activity-summary with start_time='today' and end_time='now'.
Group time by app and project. Write a concise markdown report of where
the time went and the top 3 time sinks to ~/notes/time/{date}.md, then
send a desktop notification (POST localhost:11435/notify) with a
screenpipe://timeline link to the largest time sink.
```

## Built-in pipes (don't reinvent)

meeting-summary · day-recap · standup-update · time-breakdown ·
ai-prompt-journal · video-export. Check `GET /pipes/list` before creating
something that already exists.
