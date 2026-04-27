#!/bin/bash
# Claude Session Continuity — installer
# Works both locally (./install.sh) and via curl-pipe (curl ... | bash).

set -euo pipefail

REPO_URL="https://github.com/nardovibecoding/simply-session-continuity"
CACHE_DIR="$HOME/.cache/simply-session-continuity"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SKILLS_DIR="$CLAUDE_DIR/skills"
SETTINGS="$CLAUDE_DIR/settings.json"

SCRIPT_PATH="${BASH_SOURCE[0]:-}"
if [ -n "$SCRIPT_PATH" ] && [ -d "$(dirname "$SCRIPT_PATH")/hooks" ]; then
  REPO_DIR="$(cd "$(dirname "$SCRIPT_PATH")" && pwd)"
else
  echo "→ Fetching latest..."
  rm -rf "$CACHE_DIR"
  git clone --depth 1 --quiet "$REPO_URL" "$CACHE_DIR"
  REPO_DIR="$CACHE_DIR"
fi

echo "→ Installing to $CLAUDE_DIR"
mkdir -p "$HOOKS_DIR" "$SKILLS_DIR"

cp "$REPO_DIR/hooks/session_end_logger.sh" "$HOOKS_DIR/session_end_logger.sh"
cp "$REPO_DIR/hooks/session_start_pending_save.py" "$HOOKS_DIR/session_start_pending_save.py"
chmod +x "$HOOKS_DIR/session_end_logger.sh" "$HOOKS_DIR/session_start_pending_save.py"
echo "  ✓ hooks"

cp -R "$REPO_DIR/skills/s" "$SKILLS_DIR/s"
cp -R "$REPO_DIR/skills/crash" "$SKILLS_DIR/crash"
echo "  ✓ skills (/s, /crash)"

[ -f "$SETTINGS" ] || echo '{"hooks":{}}' > "$SETTINGS"

python3 - "$SETTINGS" "$HOOKS_DIR" << 'PYEOF'
import json, sys
from pathlib import Path

settings_path = Path(sys.argv[1])
hooks_dir = sys.argv[2]
s = json.loads(settings_path.read_text())
s.setdefault("hooks", {})

def add_hook(event, matcher, cmd, timeout):
    blocks = s["hooks"].setdefault(event, [])
    for block in blocks:
        if block.get("matcher") == matcher:
            for h in block.get("hooks", []):
                if h.get("command") == cmd:
                    return
            block.setdefault("hooks", []).append(
                {"type": "command", "command": cmd, "timeout": timeout}
            )
            return
    blocks.append({
        "matcher": matcher,
        "hooks": [{"type": "command", "command": cmd, "timeout": timeout}],
    })

add_hook("SessionEnd", "*", f"{hooks_dir}/session_end_logger.sh", 1000)
add_hook("UserPromptSubmit", "", f"python3 {hooks_dir}/session_start_pending_save.py", 1000)
settings_path.write_text(json.dumps(s, indent=2))
print("  ✓ settings.json patched")
PYEOF

echo ""
echo "✅ Done. Try /s, /crash, or just /clear — your session auto-saves."
