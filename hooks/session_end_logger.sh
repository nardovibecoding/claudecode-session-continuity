#!/bin/bash
# SessionEnd: log every fire + queue deferred save marker.
# Input (stdin): {"session_id":"...","reason":"clear|exit|other|...","transcript_path":"...","cwd":"..."}
INPUT=$(cat 2>/dev/null || echo '{}')

python3 - "$INPUT" << 'PYEOF'
import json, sys, os, time
from pathlib import Path

try:
    d = json.loads(sys.argv[1])
except Exception:
    d = {}

sid = d.get("session_id", "unknown")
reason = d.get("reason", "?")
transcript = d.get("transcript_path", "")
cwd = d.get("cwd") or os.getcwd()

# Always log for observability
log = Path("/tmp/session_end_fired.log")
with log.open("a") as f:
    f.write(f"{time.strftime('%Y-%m-%dT%H:%M:%S%z')} SessionEnd reason={reason} session={sid[:8]} cwd={cwd}\n")

# Skip queue if: no transcript, trivial session, or cwd in skip list
SKIP_CWDS = os.environ.get("SESSION_CONTINUITY_SKIP_CWDS", "").split(":")
if not transcript or not Path(transcript).exists():
    sys.exit(0)
if any(s and s in cwd for s in SKIP_CWDS):
    sys.exit(0)
if Path(transcript).stat().st_size < 5000:
    sys.exit(0)

# Queue for next SessionStart
q = Path("/tmp/pending_saves")
q.mkdir(exist_ok=True)
marker = q / f"{sid}.json"
marker.write_text(json.dumps({
    "session_id": sid,
    "reason": reason,
    "transcript_path": transcript,
    "cwd": cwd,
    "ended_at": time.strftime('%Y-%m-%dT%H:%M:%S%z'),
}))
PYEOF
