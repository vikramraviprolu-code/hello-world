#!/usr/bin/env bash
# Install ALL skills in this repo at the user level (~/.claude/skills) so
# they're available in every Claude Code project on this machine.
#   bash .claude/skills/install-all.sh          (copy)
#   bash .claude/skills/install-all.sh --link   (symlink; updates on git pull)
#
# Note: yodha-memory's capture runtime needs its own setup — after this,
# run: bash .claude/skills/yodha-memory/setup/install.sh (macOS only).
set -euo pipefail

SRC_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_ROOT="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills"
mkdir -p "$DEST_ROOT"

for dir in "$SRC_ROOT"/*/; do
  name="$(basename "$dir")"
  [[ -f "$dir/SKILL.md" ]] || continue
  dest="$DEST_ROOT/$name"
  rm -rf "$dest"
  if [[ "${1:-}" == "--link" ]]; then
    ln -s "${dir%/}" "$dest"
    echo "linked    $name"
  else
    mkdir -p "$dest"
    (cd "$dir" && find . -type d \( -name __pycache__ -o -name .cache \) -prune -o -type f -print) \
      | while read -r f; do
          mkdir -p "$dest/$(dirname "$f")"
          cp "$dir/$f" "$dest/$f"
        done
    echo "installed $name"
  fi
done

echo "Done -> $DEST_ROOT"
