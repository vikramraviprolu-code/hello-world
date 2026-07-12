#!/usr/bin/env bash
# Search the awesome-claude-skills catalog.
# Usage: catalog.sh search <term> | categories | all | refresh
set -euo pipefail

REPO_RAW="https://raw.githubusercontent.com/ComposioHQ/awesome-claude-skills/master/README.md"
CACHE="${TMPDIR:-/tmp}/awesome-claude-skills-README.md"
MAX_AGE_SECS=86400

fetch() {
  if [[ ! -f "$CACHE" ]] || [[ $(( $(date +%s) - $(stat -c %Y "$CACHE" 2>/dev/null || stat -f %m "$CACHE") )) -gt $MAX_AGE_SECS ]]; then
    curl -sS --fail --max-time 30 -o "$CACHE" "$REPO_RAW"
  fi
}

# Print catalog entries as: NAME \t URL \t DESCRIPTION
entries() {
  grep -E '^\s*[-*] \[' "$CACHE" \
    | sed -E 's/^\s*[-*] \[([^]]+)\]\(([^)]+)\)[[:space:]]*-?[[:space:]]*/\1\t\2\t/' \
    | sed -E 's/\*By \[[^]]*\]\([^)]*\)\*//; s/[[:space:]]+$//'
}

cmd="${1:-}"; shift || true
case "$cmd" in
  refresh) rm -f "$CACHE"; fetch; echo "refreshed" ;;
  categories) fetch; awk '/^## Skills/{f=1;next} /^## /{f=0} f&&/^### /' "$CACHE" | sed 's/^### //' ;;
  all) fetch; entries ;;
  search)
    term="${1:?usage: catalog.sh search <term>}"
    fetch
    entries | grep -i -- "$term" || { echo "no matches for '$term'" >&2; exit 1; }
    ;;
  *) echo "usage: catalog.sh search <term> | categories | all | refresh" >&2; exit 2 ;;
esac
