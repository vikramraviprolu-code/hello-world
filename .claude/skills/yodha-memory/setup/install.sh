#!/usr/bin/env bash
# Yodha Memory installer (macOS only).
#   bash .claude/skills/yodha-memory/setup/install.sh
# Installs: the runtime at ~/.yodha-memory, a launchd agent capturing every
# 60s, and the Claude Code skill at ~/.claude/skills/yodha-memory.
set -euo pipefail

if [[ "$(uname)" != "Darwin" ]]; then
  echo "error: Yodha Memory capture runs on macOS only." >&2
  exit 1
fi

SKILL_SRC="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DIR="$HOME/.yodha-memory"
PLIST="$HOME/Library/LaunchAgents/com.yodha.memory.plist"

echo "==> Runtime files -> $DIR"
mkdir -p "$DIR/bin" "$DIR/log" "$DIR/frames"
cp "$SKILL_SRC/bin/memory.py" "$SKILL_SRC/bin/capture.sh" "$SKILL_SRC/bin/ocr.swift" "$DIR/bin/"
chmod +x "$DIR/bin/capture.sh"
[[ -f "$DIR/exclusions.txt" ]] || cp "$SKILL_SRC/setup/exclusions.txt" "$DIR/exclusions.txt"
if [[ ! -f "$DIR/config.sh" ]]; then
  cat > "$DIR/config.sh" <<'EOF'
# Yodha Memory config (shell-sourced by capture.sh)
INTERVAL=60          # seconds between captures (also set StartInterval in the plist)
RETENTION_DAYS=30    # prune frames older than this
KEEP_IMAGES=0        # 1 = keep screenshot JPEGs (more disk), 0 = text only
EOF
fi

echo "==> Compiling OCR helper (Apple Vision)"
if ! xcrun --find swiftc >/dev/null 2>&1; then
  echo "error: Swift compiler not found. Install Command Line Tools first:" >&2
  echo "  xcode-select --install" >&2
  echo "then re-run this script." >&2
  exit 1
fi
xcrun swiftc -O "$DIR/bin/ocr.swift" -o "$DIR/bin/ocr"
echo "    built $DIR/bin/ocr"

echo "==> Claude Code skill -> ~/.claude/skills/yodha-memory"
DEST="${CLAUDE_CONFIG_DIR:-$HOME/.claude}/skills/yodha-memory"
rm -rf "$DEST"
mkdir -p "$DEST"
(cd "$SKILL_SRC" && find . -type f -print) | while read -r f; do
  mkdir -p "$DEST/$(dirname "$f")"
  cp "$SKILL_SRC/$f" "$DEST/$f"
done

echo "==> launchd agent"
sed "s|__HOME__|$HOME|g" "$SKILL_SRC/setup/com.yodha.memory.plist" > "$PLIST"
launchctl bootout "gui/$(id -u)" "$PLIST" 2>/dev/null || true
launchctl bootstrap "gui/$(id -u)" "$PLIST"
echo "    loaded com.yodha.memory (every 60s)"

echo
echo "IMPORTANT — one manual step:"
echo "  The first capture will trigger a macOS 'Screen Recording' permission"
echo "  prompt (or fail silently). Grant it in:"
echo "    System Settings -> Privacy & Security -> Screen & System Audio Recording"
echo "  to the app shown (bash/Terminal). Then captures start automatically."
echo
echo "Verify in ~2 minutes with:"
echo "  /usr/bin/python3 $DIR/bin/memory.py stats"
echo "  tail -5 $DIR/log/capture.log"
echo
echo "Edit exclusions any time: $DIR/exclusions.txt (applies next cycle)."
