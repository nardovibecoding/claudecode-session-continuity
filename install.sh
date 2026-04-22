#!/bin/bash
# Claude Session Continuity — installer
# Copies hooks + skills to ~/.claude/ and patches settings.json.

set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
CLAUDE_DIR="$HOME/.claude"
HOOKS_DIR="$CLAUDE_DIR/hooks"
SKILLS_DIR="$CLAUDE_DIR/skills"
SETTINGS="$CLAUDE_DIR/settings.json"

echo "→ Installing Claude Session Continuity"

mkdir -p "$HOOKS_DIR" "$SKILLS_DIR"

# 1. Copy hooks
cp "$REPO_DIR/hooks/session_end_logger.sh" "$HOOKS_DIR/session_end_logger.sh"
cp "$REPO_DIR/hooks/session_start_pending_save.py" "$HOOKS_DIR/session_start_pending_save.py"
chmod +x "$HOOKS_DIR/session_end_logger.sh" "$HOOKS_DIR/session_start_pending_save.py"
echo "  ✓ hooks installed"

# 2. Copy skills
cp -r "$REPO_DIR/skills/s" "$SKILLS_DIR/s"
cp -r "$REPO_DIR/skills/crash" "$SKILLS_DIR/crash"
echo "  ✓ skills installed (/s, /crash)"

# 3. Patch settings.json
if [ ! -f "$SETTINGS" ]; then
  echo '{"hooks":{}}' > "$SETTINGS"
fi

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
                    return  # already installed
            block.setdefault("hooks", []).append(
                {"type": "command", "command": cmd, "timeout": timeout}
            )
            return
    blocks.append({
        "matcher": matcher,
        "hooks": [{"type": "command", "command": cmd, "timeout": timeout}]
    })

add_hook("SessionEnd", "*", f"{hooks_dir}/session_end_logger.sh", 1000)
add_hook("UserPromptSubmit", "", f"python3 {hooks_dir}/session_start_pending_save.py", 1000)

settings_path.write_text(json.dumps(s, indent=2))
print("  ✓ settings.json patched")
PYEOF

echo ""
echo "✅ Installed. Next steps:"
echo "  • Run /s anytime to save current conversation"
echo "  • Run /crash to bulk-recover sessions from today's JSONLs"
echo "  • Deferred-save auto-triggers when a session ends without /s"
echo ""
echo "Optional: skip deferred-save for specific cwd patterns (e.g. bot subprocesses):"
echo "  export SESSION_CONTINUITY_SKIP_CWDS='telegram-bot:admin-bot'"
