---
name: crash
description: Bulk-recover crashed or force-closed Claude Code sessions from today's JSONLs. Triggers: /crash
user-invocable: true
---

<crash>
Bulk-recover sessions that ended without /s (crash, force-quit, SIGKILL).
Spawn ONE background agent, exit fast.

## Step 1: Print
"Scanning today's jsonls... agent running in bg."

## Step 2: Spawn agent (model=haiku, run_in_background=true)

Prompt to agent:

"Recover unsaved Claude Code sessions.

DATE = today (YYYY-MM-DD, use `date +%Y-%m-%d`).
PROJECT_DIR = glob ~/.claude/projects/ and pick the one matching current cwd.
JSONL_DIR = $PROJECT_DIR
MEM_DIR = $PROJECT_DIR/memory/

### A) Inventory
1. List all $JSONL_DIR/*.jsonl modified on DATE.
2. Skip files <10KB (empty/stub sessions).
3. List existing $MEM_DIR/convo_DATE_*.md — extract topic slugs.

### B) Classify each jsonl
For each jsonl >=10KB:
- Sample first 8KB + last 8KB (jsonl lines can be huge).
- Extract first user message + last user/assistant content.
- Infer topic slug (1-3 words, kebab-case).
- Match against existing saved slugs — skip if already saved (fuzzy: substring or 80% word overlap).

### C) Save unsaved sessions
For each unsaved jsonl, write $MEM_DIR/convo_DATE_<slug>.md using the structured template
(## Active Task / ## Resolved / ## Pending User Asks / ## Remaining Work / ## State Deltas / ## Pivots).
Hard 3KB cap per file.

Add crashed-recovered marker:
```yaml
---
date: DATE
topic: <slug>
session_id: <jsonl basename>
status: crashed-recovered
---
```

### D) Report
- N scanned, N already-saved (skipped), N newly saved, N skipped as trivial.
- List new filenames.
- Flag any jsonls with visible crash signatures (truncated tool calls, errors in last lines)."

## Step 3: Exit
Do not wait. User gets notified when agent completes.
</crash>
