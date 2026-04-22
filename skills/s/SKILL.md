---
name: s
description: Quick-save current conversation to memory as a structured summary. Triggers: /s
user-invocable: true
---
<s>
Save current conversation as a structured summary. Run in background so user isn't blocked.

## Step 1: Print
- Print: "Saving... /s"

## Step 2: Spawn background agent (model=haiku, run_in_background=true)

Prompt to agent:

"Save current conversation as a structured summary.

A) Read the session transcript (path is in /tmp/claude_statusline.json -> transcript_path; tail the last ~300 lines).

B) Infer a 1-3 word kebab-case topic slug from the first substantive user message.

C) Write summary to ~/.claude/projects/<project-slug>/memory/convo_YYYY-MM-DD_<slug>.md.

(The project-slug is the directory name under ~/.claude/projects/ matching current cwd.
Glob ~/.claude/projects/*/ to find it, or derive by escaping cwd with / -> -.)

**Hard cap: 3KB per file.** Compress harder if overflow — never exceed.

Template (skip empty sections):

```
---
date: YYYY-MM-DD
topic: <slug>
session_id: <jsonl basename>
---

# <Topic title>

## Active Task
<what was in progress at save time, 1-3 lines>

## Resolved
<what got done this session, bullets>

## Pending User Asks
<unanswered questions, numbered, or omit>

## Remaining Work
<concrete next steps>

## State Deltas
<enabled/disabled/param changes, or omit>

## Pivots
<position flips or scope changes during session, or omit>
```

D) touch /tmp/claude_auto_save_done

E) Report: filename saved."
</s>
