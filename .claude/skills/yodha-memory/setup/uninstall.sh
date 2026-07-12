#!/usr/bin/env bash
# Stop and remove Yodha Memory.
#   bash uninstall.sh          — stop capture, keep your data
#   bash uninstall.sh --purge  — also delete ~/.yodha-memory (ALL memory data)
set -euo pipefail

PLIST="$HOME/Library/LaunchAgents/com.yodha.memory.plist"
launchctl bootout "gui/$(id -u)" "$PLIST" 2>/dev/null || true
rm -f "$PLIST"
echo "Capture agent stopped and removed."

rm -rf "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/yodha-memory"
echo "Claude skill removed."

if [[ "${1:-}" == "--purge" ]]; then
  rm -rf "$HOME/.yodha-memory"
  echo "All memory data deleted (~/.yodha-memory)."
else
  echo "Data kept at ~/.yodha-memory (pass --purge to delete it)."
fi
