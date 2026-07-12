#!/usr/bin/env bash
# Fetch system-prompt files for a given AI tool from
# x1xhlol/system-prompts-and-models-of-ai-tools (branch: main).
#
# Usage:
#   fetch_prompt.sh "Cursor Prompts"      # download all files under that folder
#   fetch_prompt.sh --list "Devin AI"     # list files only, no download
#   fetch_prompt.sh --root                # list top-level folders in the repo
#
# Files are saved under: <skill_dir>/.cache/<folder>/...
# Requires: curl, jq. Honors GITHUB_TOKEN if set (raises rate limits).

set -euo pipefail

REPO="x1xhlol/system-prompts-and-models-of-ai-tools"
BRANCH="main"
SKILL_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
CACHE_DIR="$SKILL_DIR/.cache"

AUTH=()
if [[ -n "${GITHUB_TOKEN:-}" ]]; then
  AUTH=(-H "Authorization: Bearer $GITHUB_TOKEN")
fi

api() {
  curl -sS --fail --max-time 30 "${AUTH[@]}" \
    -H "Accept: application/vnd.github+json" "$1"
}

list_root() {
  echo "Top-level folders in $REPO (branch $BRANCH):"
  api "https://api.github.com/repos/$REPO/contents/?ref=$BRANCH" \
    | jq -r '.[] | select(.type=="dir") | "  " + .name'
}

# Recursively list blob paths under a folder prefix using the git trees API.
list_paths() {
  local folder="$1"
  api "https://api.github.com/repos/$REPO/git/trees/$BRANCH?recursive=1" \
    | jq -r --arg p "$folder/" \
        '.tree[] | select(.type=="blob") | select(.path | startswith($p)) | .path'
}

raw_url() {
  # URL-encode each path segment, keep slashes.
  python3 -c '
import sys, urllib.parse
print("/".join(urllib.parse.quote(s) for s in sys.argv[1].split("/")))
' "$1"
}

main() {
  local mode="download" folder=""
  case "${1:-}" in
    --root) list_root; exit 0 ;;
    --list) mode="list"; folder="${2:-}" ;;
    "" ) echo "error: provide a folder name (or --root / --list <folder>)" >&2; exit 2 ;;
    *  ) folder="$1" ;;
  esac

  if [[ -z "$folder" ]]; then
    echo "error: missing folder name" >&2; exit 2
  fi

  mapfile -t paths < <(list_paths "$folder")
  if [[ ${#paths[@]} -eq 0 ]]; then
    echo "No files found under \"$folder\". Run with --root to see valid folders." >&2
    exit 1
  fi

  if [[ "$mode" == "list" ]]; then
    printf '%s\n' "${paths[@]}"
    exit 0
  fi

  local dest_base="$CACHE_DIR/$folder"
  mkdir -p "$dest_base"
  echo "Downloading ${#paths[@]} file(s) into $dest_base"
  for path in "${paths[@]}"; do
    local rel="${path#"$folder"/}"
    local dest="$dest_base/$rel"
    mkdir -p "$(dirname "$dest")"
    local url="https://raw.githubusercontent.com/$REPO/$BRANCH/$(raw_url "$path")"
    if curl -sS --fail --max-time 60 "${AUTH[@]}" -o "$dest" "$url"; then
      echo "  saved: $dest"
    else
      echo "  FAILED: $path" >&2
    fi
  done
}

main "$@"
