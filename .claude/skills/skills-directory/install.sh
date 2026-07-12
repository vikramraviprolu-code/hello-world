#!/usr/bin/env bash
# Install the skills-directory skill at the user level so it is available in every
# Claude Code project on this machine.
#   bash .claude/skills/skills-directory/install.sh          (copy)
#   bash .claude/skills/skills-directory/install.sh --link   (symlink; updates on git pull)
set -euo pipefail

SRC_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DEST_DIR="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/skills-directory"

mkdir -p "$(dirname "$DEST_DIR")"

if [[ "${1:-}" == "--link" ]]; then
  rm -rf "$DEST_DIR"
  ln -s "$SRC_DIR" "$DEST_DIR"
  echo "Linked $DEST_DIR -> $SRC_DIR"
else
  rm -rf "$DEST_DIR"
  mkdir -p "$DEST_DIR"
  (cd "$SRC_DIR" && find . -type f -print) | while read -r f; do
    mkdir -p "$DEST_DIR/$(dirname "$f")"
    cp "$SRC_DIR/$f" "$DEST_DIR/$f"
  done
  echo "Installed skill to $DEST_DIR"
fi

echo "Done. The 'skills-directory' skill is now available in every Claude Code project."
