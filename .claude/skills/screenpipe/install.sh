#!/usr/bin/env bash
# Install the screenpipe skill at the user level so it is available in every
# Claude Code project on this machine (not just this repo).
#
# Run once per Mac:
#   bash .claude/skills/screenpipe/install.sh
#
# Re-run any time to update. Use --link to symlink instead of copy
# (auto-updates on `git pull`, but breaks if this repo moves or is deleted).

set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/screenpipe"

mkdir -p "$(dirname "$DEST_DIR")"

if [[ "${1:-}" == "--link" ]]; then
  rm -rf "$DEST_DIR"
  ln -s "$SRC_DIR" "$DEST_DIR"
  echo "Linked $DEST_DIR -> $SRC_DIR"
else
  rm -rf "$DEST_DIR"
  mkdir -p "$DEST_DIR"
  (cd "$SRC_DIR" && find . -type f -print) \
    | while read -r f; do
        mkdir -p "$DEST_DIR/$(dirname "$f")"
        cp "$SRC_DIR/$f" "$DEST_DIR/$f"
      done
  echo "Installed skill to $DEST_DIR"
fi

echo "Done. The 'screenpipe' skill is now available in every Claude Code project."
echo "It requires the Screenpipe app (screenpipe.com) running on this machine."
