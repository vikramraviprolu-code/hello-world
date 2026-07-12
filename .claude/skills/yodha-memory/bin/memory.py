#!/usr/bin/env python3
"""Yodha Memory — local screen-memory store (SQLite + FTS5).

Subcommands:
  insert   --ts ISO --app APP --window TITLE --text - [--img PATH]
  search   QUERY [--app APP] [--since T] [--until T] [--limit N]
  activity [--since T] [--until T]           app-usage summary
  context  --at ISO [--minutes N]            frames around a moment
  stats                                      db size, range, counts
  prune    --days N                          delete rows + images older than N days

Times: ISO 8601 (2026-07-02T10:00:00) or relative: '2h ago', '3d ago',
'today', 'yesterday', 'now'. All stored timestamps are UTC.

Data lives in ~/.yodha-memory/memory.db (override: YODHA_MEMORY_DIR).
"""
import argparse
import datetime as dt
import hashlib
import json
import os
import re
import sqlite3
import sys

DATA_DIR = os.environ.get(
    "YODHA_MEMORY_DIR", os.path.expanduser("~/.yodha-memory")
)
DB_PATH = os.path.join(DATA_DIR, "memory.db")

SCHEMA = """
CREATE TABLE IF NOT EXISTS frames (
  id     INTEGER PRIMARY KEY,
  ts     TEXT NOT NULL,
  app    TEXT NOT NULL DEFAULT '',
  window TEXT NOT NULL DEFAULT '',
  text   TEXT NOT NULL DEFAULT '',
  hash   TEXT NOT NULL DEFAULT '',
  img    TEXT
);
CREATE INDEX IF NOT EXISTS idx_frames_ts ON frames(ts);
CREATE INDEX IF NOT EXISTS idx_frames_app ON frames(app);
CREATE VIRTUAL TABLE IF NOT EXISTS frames_fts USING fts5(
  text, content='frames', content_rowid='id'
);
CREATE TRIGGER IF NOT EXISTS frames_ai AFTER INSERT ON frames BEGIN
  INSERT INTO frames_fts(rowid, text) VALUES (new.id, new.text);
END;
CREATE TRIGGER IF NOT EXISTS frames_ad AFTER DELETE ON frames BEGIN
  INSERT INTO frames_fts(frames_fts, rowid, text)
  VALUES ('delete', old.id, old.text);
END;
"""


def db():
    os.makedirs(DATA_DIR, exist_ok=True)
    conn = sqlite3.connect(DB_PATH)
    conn.executescript(SCHEMA)
    return conn


def parse_time(s):
    """ISO 8601 or relative ('2h ago', 'today', 'now') -> UTC datetime."""
    if not s:
        return None
    s = s.strip()
    now = dt.datetime.now(dt.timezone.utc)
    low = s.lower()
    if low == "now":
        return now
    if low == "today":
        return now.replace(hour=0, minute=0, second=0, microsecond=0)
    if low == "yesterday":
        return (now - dt.timedelta(days=1)).replace(
            hour=0, minute=0, second=0, microsecond=0
        )
    m = re.fullmatch(r"(\d+)\s*([mhdw])\s*ago", low)
    if m:
        n, unit = int(m.group(1)), m.group(2)
        delta = {"m": "minutes", "h": "hours", "d": "days", "w": "weeks"}[unit]
        return now - dt.timedelta(**{delta: n})
    try:
        parsed = dt.datetime.fromisoformat(s.replace("Z", "+00:00"))
    except ValueError:
        sys.exit(f"error: cannot parse time {s!r} (use ISO 8601 or '2h ago')")
    if parsed.tzinfo is None:
        parsed = parsed.replace(tzinfo=dt.timezone.utc)
    return parsed.astimezone(dt.timezone.utc)


def iso(t):
    return t.strftime("%Y-%m-%dT%H:%M:%SZ") if t else None


def time_clause(args, params):
    clauses = []
    since = parse_time(getattr(args, "since", None))
    until = parse_time(getattr(args, "until", None))
    if since:
        clauses.append("ts >= ?")
        params.append(iso(since))
    if until:
        clauses.append("ts <= ?")
        params.append(iso(until))
    return clauses


def cmd_insert(args):
    text = sys.stdin.read() if args.text == "-" else args.text
    text = text.strip()
    h = hashlib.sha256(
        f"{args.app}\x00{args.window}\x00{text}".encode()
    ).hexdigest()
    conn = db()
    # Dedup: skip if identical to the most recent frame (screen unchanged).
    row = conn.execute(
        "SELECT hash FROM frames ORDER BY id DESC LIMIT 1"
    ).fetchone()
    if row and row[0] == h:
        print(json.dumps({"inserted": False, "reason": "duplicate"}))
        return
    ts = iso(parse_time(args.ts) or dt.datetime.now(dt.timezone.utc))
    conn.execute(
        "INSERT INTO frames(ts, app, window, text, hash, img) "
        "VALUES (?,?,?,?,?,?)",
        (ts, args.app, args.window, text, h, args.img),
    )
    conn.commit()
    print(json.dumps({"inserted": True, "ts": ts, "app": args.app}))


def fts_escape(q):
    # Treat the query as plain words, not FTS5 syntax: quote each token.
    tokens = re.findall(r"\w+", q)
    return " ".join(f'"{t}"' for t in tokens) if tokens else '""'


def cmd_search(args):
    conn = db()
    params = [fts_escape(args.query)]
    where = ["frames_fts MATCH ?"]
    if args.app:
        where.append("f.app = ?")
        params.append(args.app)
    tw = []
    since = parse_time(args.since)
    until = parse_time(args.until)
    if since:
        tw.append("f.ts >= ?")
        params.append(iso(since))
    if until:
        tw.append("f.ts <= ?")
        params.append(iso(until))
    sql = (
        "SELECT f.id, f.ts, f.app, f.window, "
        "snippet(frames_fts, 0, '>>', '<<', ' … ', 24) AS snip "
        "FROM frames_fts JOIN frames f ON f.id = frames_fts.rowid "
        f"WHERE {' AND '.join(where + tw)} "
        "ORDER BY rank LIMIT ?"
    )
    params.append(args.limit)
    rows = conn.execute(sql, params).fetchall()
    out = [
        {"frame_id": r[0], "ts": r[1], "app": r[2], "window": r[3],
         "snippet": r[4]}
        for r in rows
    ]
    print(json.dumps(out, indent=2))


def cmd_activity(args):
    conn = db()
    params = []
    tw = time_clause(args, params)
    where = f"WHERE {' AND '.join(tw)}" if tw else ""
    # Each stored frame ≈ one capture interval of activity in that app.
    rows = conn.execute(
        f"SELECT app, COUNT(*) AS frames, MIN(ts), MAX(ts), "
        f"COUNT(DISTINCT window) AS windows "
        f"FROM frames {where} GROUP BY app ORDER BY frames DESC",
        params,
    ).fetchall()
    interval = int(os.environ.get("YODHA_CAPTURE_INTERVAL", "60"))
    out = [
        {"app": r[0], "approx_minutes": round(r[1] * interval / 60),
         "captures": r[1], "distinct_windows": r[4],
         "first_seen": r[2], "last_seen": r[3]}
        for r in rows
    ]
    print(json.dumps(out, indent=2))


def cmd_context(args):
    conn = db()
    at = parse_time(args.at)
    lo = iso(at - dt.timedelta(minutes=args.minutes))
    hi = iso(at + dt.timedelta(minutes=args.minutes))
    rows = conn.execute(
        "SELECT id, ts, app, window, substr(text, 1, 2000) FROM frames "
        "WHERE ts BETWEEN ? AND ? ORDER BY ts",
        (lo, hi),
    ).fetchall()
    out = [
        {"frame_id": r[0], "ts": r[1], "app": r[2], "window": r[3],
         "text": r[4]}
        for r in rows
    ]
    print(json.dumps(out, indent=2))


def cmd_stats(_args):
    conn = db()
    n, lo, hi = conn.execute(
        "SELECT COUNT(*), MIN(ts), MAX(ts) FROM frames"
    ).fetchone()
    apps = conn.execute("SELECT COUNT(DISTINCT app) FROM frames").fetchone()[0]
    size = os.path.getsize(DB_PATH) if os.path.exists(DB_PATH) else 0
    print(json.dumps({
        "frames": n, "apps": apps, "oldest": lo, "newest": hi,
        "db_path": DB_PATH, "db_mb": round(size / 1e6, 1),
    }, indent=2))


def cmd_prune(args):
    conn = db()
    cutoff = iso(
        dt.datetime.now(dt.timezone.utc) - dt.timedelta(days=args.days)
    )
    imgs = conn.execute(
        "SELECT img FROM frames WHERE ts < ? AND img IS NOT NULL", (cutoff,)
    ).fetchall()
    removed = 0
    for (img,) in imgs:
        try:
            os.remove(img)
            removed += 1
        except OSError:
            pass
    cur = conn.execute("DELETE FROM frames WHERE ts < ?", (cutoff,))
    conn.commit()
    conn.execute("VACUUM")
    print(json.dumps({
        "deleted_frames": cur.rowcount, "deleted_images": removed,
        "cutoff": cutoff,
    }))


def main():
    p = argparse.ArgumentParser(description=__doc__)
    sub = p.add_subparsers(dest="cmd", required=True)

    i = sub.add_parser("insert")
    i.add_argument("--ts", default=None)
    i.add_argument("--app", default="")
    i.add_argument("--window", default="")
    i.add_argument("--text", required=True, help="text or '-' for stdin")
    i.add_argument("--img", default=None)
    i.set_defaults(fn=cmd_insert)

    s = sub.add_parser("search")
    s.add_argument("query")
    s.add_argument("--app", default=None)
    s.add_argument("--since", default=None)
    s.add_argument("--until", default=None)
    s.add_argument("--limit", type=int, default=10)
    s.set_defaults(fn=cmd_search)

    a = sub.add_parser("activity")
    a.add_argument("--since", default=None)
    a.add_argument("--until", default=None)
    a.set_defaults(fn=cmd_activity)

    c = sub.add_parser("context")
    c.add_argument("--at", required=True)
    c.add_argument("--minutes", type=int, default=5)
    c.set_defaults(fn=cmd_context)

    st = sub.add_parser("stats")
    st.set_defaults(fn=cmd_stats)

    pr = sub.add_parser("prune")
    pr.add_argument("--days", type=int, required=True)
    pr.set_defaults(fn=cmd_prune)

    args = p.parse_args()
    args.fn(args)


if __name__ == "__main__":
    main()
