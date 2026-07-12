#!/bin/bash
# SessionStart hook: install this repo's Claude skills globally
# (~/.claude/skills) so they're available in every project during
# Claude Code on the web sessions. Idempotent; never blocks session start.
set -uo pipefail

# Only run in the remote (web) environment.
if [ "${CLAUDE_CODE_REMOTE:-}" != "true" ]; then
  exit 0
fi

REPO="${CLAUDE_PROJECT_DIR:-$(cd "$(dirname "$0")/../.." && pwd)}"
INSTALLER="$REPO/.claude/skills/install-all.sh"

if [ -x "$INSTALLER" ]; then
  bash "$INSTALLER" || echo "session-start: install-all.sh failed (non-fatal)"
else
  echo "session-start: installer not found at $INSTALLER (skipped)"
fi

exit 0
