#!/usr/bin/env python3
"""UserPromptSubmit hook: surface pending deferred-saves from /tmp/pending_saves/.

On first user prompt per session, injects additionalContext nudging Claude
to spawn a background Agent that runs /s-equivalent on each orphaned
transcript.
"""
import json
import sys
from pathlib import Path

QUEUE = Path("/tmp/pending_saves")
DONE_MARKER = Path("/tmp/claude_pending_save_injected")


def main():
    try:
        event = json.load(sys.stdin)
    except Exception:
        event = {}

    if DONE_MARKER.exists():
        print("{}")
        return

    if not QUEUE.exists():
        print("{}")
        return

    markers = sorted(QUEUE.glob("*.json"))
    if not markers:
        print("{}")
        return

    lines = []
    for m in markers[:10]:
        try:
            d = json.loads(m.read_text())
            sid = d.get("session_id", "?")[:8]
            reason = d.get("reason", "?")
            tp = d.get("transcript_path", "")
            lines.append(f"- session={sid} reason={reason} transcript={tp} marker={m}")
        except Exception:
            continue

    if not lines:
        print("{}")
        return

    nudge = (
        f"DEFERRED SAVE QUEUE — {len(lines)} prior session(s) ended without /s.\n"
        f"{chr(10).join(lines)}\n\n"
        "BEFORE responding to the user, spawn ONE background Agent "
        "(model=haiku, run_in_background=true) with this prompt:\n\n"
        "\"For each pending marker in /tmp/pending_saves/*.json: read the transcript "
        "JSONL at its transcript_path, infer a 1-3 word topic slug from the first "
        "substantive user message, check if ~/.claude/projects/<project-slug>/memory/"
        "convo_YYYY-MM-DD_<slug>.md already exists (skip if yes), else write one using "
        "the structured template (## Active Task / ## Resolved / ## Pending User Asks "
        "/ ## Remaining Work / ## State Deltas / ## Pivots). Hard 3KB cap per file. "
        "Delete the marker after save. Report N saved, N skipped.\"\n\n"
        "Then: touch /tmp/claude_pending_save_injected (prevents re-nudge this session). "
        "Then respond to the user normally."
    )

    out = {
        "hookSpecificOutput": {
            "hookEventName": event.get("hook_event_name", "UserPromptSubmit"),
            "additionalContext": nudge,
        }
    }
    print(json.dumps(out))


if __name__ == "__main__":
    main()
