#!/usr/bin/env bash
# Thin curl wrapper around the local Screenpipe REST API (localhost:3030).
#
# Usage:
#   sp.sh health
#   sp.sh activity <start_time> [end_time] [app_name]
#   sp.sh search <query> [--type all|ocr|audio|input|memory] [--since T]
#                [--until T] [--app NAME] [--limit N]
#   sp.sh meetings [--since T] [--q FILTER] [--limit N]
#   sp.sh raw "/search?content_type=audio&start_time=2h%20ago&limit=5"
#
# Times: ISO 8601 UTC or relative ("2h ago", "today", "now").
# Env: SCREENPIPE_API_URL (default http://localhost:3030),
#      SCREENPIPE_LOCAL_API_KEY (sent as Bearer token if set).

set -euo pipefail

API="${SCREENPIPE_API_URL:-http://localhost:3030}"
AUTH=()
if [[ -n "${SCREENPIPE_LOCAL_API_KEY:-${SCREENPIPE_API_KEY:-}}" ]]; then
  AUTH=(-H "Authorization: Bearer ${SCREENPIPE_LOCAL_API_KEY:-$SCREENPIPE_API_KEY}")
fi

get() {
  local path="$1"
  if ! curl -sS --fail-with-body --max-time 30 "${AUTH[@]}" "$API$path"; then
    echo >&2
    echo "error: request to $API$path failed. Is Screenpipe running? (open the app or run \`screenpipe\`)" >&2
    exit 1
  fi
  echo
}

enc() { jq -rn --arg v "$1" '$v|@uri'; }

cmd="${1:-}"; shift || true
case "$cmd" in
  health)
    get "/health"
    ;;
  activity)
    start="${1:?usage: sp.sh activity <start_time> [end_time] [app_name]}"
    end="${2:-now}"
    q="start_time=$(enc "$start")&end_time=$(enc "$end")"
    [[ -n "${3:-}" ]] && q="$q&app_name=$(enc "$3")"
    get "/activity-summary?$q"
    ;;
  search)
    query=""; type="all"; since=""; until=""; app=""; limit=5
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --type)  type="$2"; shift 2 ;;
        --since) since="$2"; shift 2 ;;
        --until) until="$2"; shift 2 ;;
        --app)   app="$2"; shift 2 ;;
        --limit) limit="$2"; shift 2 ;;
        *)       query="$1"; shift ;;
      esac
    done
    q="content_type=$(enc "$type")&limit=$limit"
    [[ -n "$query" ]] && q="$q&q=$(enc "$query")"
    [[ -n "$since" ]] && q="$q&start_time=$(enc "$since")"
    [[ -n "$until" ]] && q="$q&end_time=$(enc "$until")"
    [[ -n "$app"   ]] && q="$q&app_name=$(enc "$app")"
    get "/search?$q"
    ;;
  meetings)
    since=""; filter=""; limit=20
    while [[ $# -gt 0 ]]; do
      case "$1" in
        --since) since="$2"; shift 2 ;;
        --q)     filter="$2"; shift 2 ;;
        --limit) limit="$2"; shift 2 ;;
        *) shift ;;
      esac
    done
    q="limit=$limit"
    [[ -n "$since"  ]] && q="$q&start_time=$(enc "$since")"
    [[ -n "$filter" ]] && q="$q&q=$(enc "$filter")"
    get "/meetings?$q"
    ;;
  raw)
    get "${1:?usage: sp.sh raw \"/endpoint?params\"}"
    ;;
  *)
    sed -n '2,15p' "$0" | sed 's/^# \{0,1\}//'
    exit 2
    ;;
esac
