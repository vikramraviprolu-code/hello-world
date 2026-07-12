#!/usr/bin/env bash
# Yodha Memory — one capture cycle (macOS). Run by launchd every INTERVAL s.
# Screenshot -> exclusion check -> OCR (Apple Vision) -> SQLite insert.
set -uo pipefail

DIR="${YODHA_MEMORY_DIR:-$HOME/.yodha-memory}"
CONFIG="$DIR/config.sh"
[[ -f "$CONFIG" ]] && source "$CONFIG"
INTERVAL="${INTERVAL:-60}"
RETENTION_DAYS="${RETENTION_DAYS:-30}"
KEEP_IMAGES="${KEEP_IMAGES:-0}"
export YODHA_MEMORY_DIR="$DIR" YODHA_CAPTURE_INTERVAL="$INTERVAL"

MEMORY="$DIR/bin/memory.py"
OCR="$DIR/bin/ocr"
LOG="$DIR/log/capture.log"
mkdir -p "$DIR/log" "$DIR/frames"

log() { echo "$(date -u +%FT%TZ) $*" >> "$LOG"; }

if [[ ! -x "$OCR" ]]; then
  log "ERROR: OCR binary missing at $OCR — re-run install.sh"
  exit 1
fi

# Frontmost app + window title (window title may be unavailable; that's fine).
APP="$(osascript -e 'tell application "System Events" to get name of first application process whose frontmost is true' 2>/dev/null || echo unknown)"
WIN="$(osascript -e 'tell application "System Events" to get name of front window of (first application process whose frontmost is true)' 2>/dev/null || echo "")"

# Exclusions: one case-insensitive glob per line, matched against app OR window.
EXCL="$DIR/exclusions.txt"
if [[ -f "$EXCL" ]]; then
  shopt -s nocasematch
  while IFS= read -r pat; do
    [[ -z "$pat" || "$pat" == \#* ]] && continue
    if [[ "$APP" == $pat || "$WIN" == $pat ]]; then
      log "skip (excluded: $pat) app=$APP"
      exit 0
    fi
  done < "$EXCL"
  shopt -u nocasematch
fi

TS="$(date -u +%FT%TZ)"
TMP="$(mktemp -t yodha_frame).jpg"
trap 'rm -f "$TMP"' EXIT

# -x silent, main display. (Multi-monitor: MVP captures the main display.)
if ! screencapture -x -t jpg "$TMP" 2>>"$LOG"; then
  log "ERROR: screencapture failed (Screen Recording permission granted?)"
  exit 1
fi

TEXT="$("$OCR" "$TMP" 2>>"$LOG")"
if [[ -z "${TEXT// /}" ]]; then
  log "skip (no text) app=$APP"
  exit 0
fi

IMG_ARG=()
if [[ "$KEEP_IMAGES" == "1" ]]; then
  DEST="$DIR/frames/$(date -u +%Y/%m/%d)"
  mkdir -p "$DEST"
  FINAL="$DEST/$(date -u +%H%M%S).jpg"
  cp "$TMP" "$FINAL"
  IMG_ARG=(--img "$FINAL")
fi

RESULT="$(printf '%s' "$TEXT" | /usr/bin/python3 "$MEMORY" insert \
  --ts "$TS" --app "$APP" --window "$WIN" --text - "${IMG_ARG[@]}" 2>>"$LOG")"
log "capture app=$APP win=${WIN:0:40} $RESULT"

# Housekeeping once an hour (first cycle of the hour).
if [[ "$(date -u +%M)" == "00" ]]; then
  /usr/bin/python3 "$MEMORY" prune --days "$RETENTION_DAYS" >> "$LOG" 2>&1
fi
