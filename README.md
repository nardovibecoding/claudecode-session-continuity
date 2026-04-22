# Claude Session Continuity

**Your Claude Code conversations don't have to disappear.**

You know the moment. You `/clear` by reflex. Or close a terminal with a pending plan inside. Or the laptop dies mid-session. Ninety minutes of context — the design you debugged, the decisions you finally reached, the state Claude had just built up — gone. Next time you open Claude, it knows nothing.

This fixes that. Three commands, two hooks, zero API calls.

```bash
curl -fsSL https://raw.githubusercontent.com/nardovibecoding/claudecode-session-continuity/main/install.sh | bash
```

After the install: `/s` saves the current session. `/crash` recovers any session that ended without `/s`. Deferred-save auto-triggers on `/clear` or terminal close — so the accidental losses catch themselves.

**Platform**: macOS + Linux. Requires Claude Code + Python 3.

---

## The three moves

### `/s` — save on demand

Type `/s` anywhere in a Claude Code session. A background Haiku agent reads the transcript and writes a structured summary to `~/.claude/projects/<project>/memory/convo_YYYY-MM-DD_<topic>.md`. Takes ~15 seconds. You keep working.

The summary isn't freeform bullets. It's a fixed template (borrowed from [hermes-agent](https://github.com/nousresearch/hermes-agent)):

```
## Active Task       — what's in progress right now
## Resolved          — what got done this session
## Pending User Asks — unanswered questions, numbered
## Remaining Work    — concrete next steps
## State Deltas      — enabled/disabled/param changes
## Pivots            — position flips during the session
```

Hard 3KB cap. Forces the agent to compress, not dump. A month of these is actually readable.

### `/crash` — recover what slipped through

Laptop crashed. You force-quit five terminals. Power cut. Claude died mid-sentence. Type `/crash`. One agent scans today's JSONLs, diffs against what's already saved, writes summaries for the orphans. Done.

### Deferred-save — the auto-layer

The failure mode you care about most: you `/clear` by reflex and only realize a second later. Or you habitually close terminals without thinking about save.

Two hooks catch these:

```
/clear or close terminal
    ↓   SessionEnd hook writes marker to /tmp/pending_saves/<session_id>.json
    ↓
Next Claude Code session — first prompt
    ↓   UserPromptSubmit hook reads the queue, nudges Claude to save
    ↓
Background Agent reads the orphaned transcript, writes convo_*.md, deletes marker
    ↓   ~20 seconds later: the session you thought you'd lost is saved
```

Works across terminals. Close a window in one project, the save fires next time you open Claude Code in any project.

**Coverage:**
- `/clear` — ✅
- Graceful close (`/exit`, Cmd+W) — ✅
- Hard kill (SIGKILL, OOM, power loss) — ❌ use `/crash`

---

## Why this structure

Most save-session tools dump freeform bullets. The bullets rot. You stop reading them. The template here answers the same six questions every time — which means a month of saves stays scannable, and an LLM can grep across them without getting confused by shape.

Hermes-agent uses this exact format for compaction handoffs. Stealing it for checkpoints gets you the same benefit at a different layer.

Pairs with [memory-wiki-graph-stack](https://github.com/nardovibecoding/memory-wiki-graph-stack) if you want the saved convos to auto-organize into a knowledge graph.

---

## Config (optional)

If you run Claude Code subprocesses inside bots (e.g. a Telegram bot spawning Claude SDK), skip them so their SessionEnd events don't pollute your save queue:

```bash
export SESSION_CONTINUITY_SKIP_CWDS='telegram-bot:admin-bot'
```

Any `cwd` containing one of those substrings is ignored.

Saves land in `~/.claude/projects/<project-slug>/memory/`, scoped per project — no cross-project bleed.

---

## How it compares

| | Manual save skills | This | hermes-agent |
|---|---|---|---|
| Save trigger | manual only | manual + auto-deferred | auto-writes to SQLite |
| Recovery after crash | manual grep | `/crash` | always queryable |
| Template | freeform | **structured** | structured |
| API cost | 0 | 0 | 0 (configurable) |
| Graph integration | no | [pair with memory-wiki-graph-stack](https://github.com/nardovibecoding/memory-wiki-graph-stack) | external plugins |

---

## License

MIT. See LICENSE.

## Credits

- Structured template from [hermes-agent](https://github.com/nousresearch/hermes-agent) by Nous Research
- Built with [Claude Code](https://claude.com/claude-code)
