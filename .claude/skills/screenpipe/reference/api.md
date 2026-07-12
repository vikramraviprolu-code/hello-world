# Screenpipe REST API reference

Base URL: `http://localhost:3030` (override with `SCREENPIPE_API_URL`).
Auth: optional — if the install requires it, send
`Authorization: Bearer $SCREENPIPE_LOCAL_API_KEY`.

Source of truth: the `screenpipe-mcp` npm package (v0.18.x), which wraps these
same endpoints. Verified 2026-07. Endpoints may drift with backend versions —
a 404 usually means a version mismatch, not a wrong path.

## GET /health

Recording status, frame/audio stats, timestamps. Use as the liveness probe.

## GET /search — main content search

Full-text search (SQLite FTS5) over screen text, audio transcriptions, input
events, and memories. Returns `{ data: [...], pagination: {...} }` with
timestamped results carrying `app_name`, `window_name`, `frame_id`.

| Param | Notes |
|---|---|
| `q` | FTS query. Omit to return everything in range. Avoid for audio (too noisy). |
| `content_type` | `all` (default) · `ocr` (ALL screen text — a11y + ocr) · `audio` · `input` · `accessibility` · `memory` |
| `start_time` / `end_time` | ISO 8601 UTC, or `2h ago`, `1d ago`, `1w ago`, `today`, `yesterday`, `now`, bare `YYYY-MM-DD`. **Always set start_time.** |
| `limit` / `offset` | Default 10, max 20. Start with 5. |
| `app_name` | Case-sensitive exact app name (`Google Chrome`, `Slack`, `zoom.us`). |
| `window_name` | Window-title substring. |
| `min_length` / `max_length` | Content length bounds in chars. |
| `speaker_ids` | Comma-separated speaker IDs (audio). |
| `speaker_name` | Case-insensitive partial speaker-name match (audio). |
| `tags` | Comma-separated; item must carry ALL (`person:ada,project:atlas`). Applies to ocr/audio/memory only. |
| `include_frames` | `true` adds base64 screenshots (OCR rows). Large — avoid. |

Screen-text rows are labeled by source: accessibility-derived vs OCR fallback.

## GET /search/keyword — fast keyword lookup

Params: `query`, `limit`, `offset`, `start_time`, `end_time`, `app_names`
(repeatable). Returns a **bare JSON array** of matches (not the
`{data, pagination}` envelope `/search` uses).

## GET /activity-summary?start_time=...&end_time=...

App usage with active minutes, window/tab titles with URLs and time spent,
key text per context, audio speaker summary. Optional `app_name` filter.
The right first call for any broad time-range question; it owns time math.

## Meetings

- `GET /meetings?start_time=...&q=...&limit=...` — detected meetings (Zoom,
  Teams, Meet…) with duration, app, attendees. `q` substring-matches title,
  attendees, and notes. Requires smart-transcription mode.

## Frames

- `GET /frames/{frame_id}/context` — full accessibility text, parsed tree
  nodes, URLs for one frame. Use after `/search`.
- `GET /frames/{frame_id}/elements?format=outline` — UI elements (buttons,
  links, fields) for a frame; filter by role (`AXButton`, `AXLink`, …).

## Audio

- `GET /audio/list` — audio devices.
- `POST /audio/start` / `POST /audio/stop` — control audio recording.

## Speakers

- `GET /speakers/search?name=...` — find speakers by name.
- Endpoints exist to list unnamed speakers, rename, and merge duplicates
  (see MCP tools `update-speaker`, `merge-speakers`).

## Tags

- `POST /tags/{content_type}/{id}` — add tags to a frame or audio chunk.
  Frames are pruned by retention; for durable links, tag a memory instead.

## Memories

Persistent user facts. Create/update/delete via the memory endpoint
(MCP `update-memory`: `content`, `tags[]`, `importance` 0.0–1.0, `id`,
`delete`). Retrieve via `GET /search?content_type=memory`.

## Pipes

- `GET /pipes/list`
- `POST /pipes/{name}/config` — e.g. `{ "schedule": "every 1h", "enabled": true }`
- Pipe files live in `~/.screenpipe/pipes/<name>/pipe.md` (see
  `reference/pipes.md`); logs via the pipe-logs mechanism.

## Raw SQL

The API allows raw SQL against `~/.screenpipe/db.sqlite` (FTS5 schema).
Last resort only; prefer the typed endpoints. Read-only queries only.

## Desktop notifications

`POST http://localhost:11435/notify` (Tauri sidecar) shows a desktop
notification — useful as a pipe output.

## Deep links

- Frame: `screenpipe://frame/{frame_id}`
- Timeline: `screenpipe://timeline?timestamp=2024-01-15T15:00:00Z`

Only use IDs/timestamps from actual results — never fabricate them.
