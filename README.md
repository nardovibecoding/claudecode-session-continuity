# Claude Session Continuity

**Never lose a Claude Code conversation again.**

Three slash commands + two hooks that turn every Claude Code session into a durable, searchable memory atom — with zero API calls.

- `/s` — save current conversation as a structured summary
- `/crash` — bulk-recover any sessions that ended without `/s` today
- **Deferred-save** — if you `/clear` or close the terminal, the session auto-saves on your next Claude Code open

Inspired by Nous Research's [hermes-agent](https://github.com/nousresearch/hermes-agent) compaction handoff format. Pairs with [memory-wiki-graph-stack](https://github.com/nardovibecoding/memory-wiki-graph-stack) if you want the saved convos to auto-organize into a knowledge graph.

**Platform**: macOS + Linux. Requires Claude Code + Python 3.

---

## Install

```bash
git clone https://github.com/nardovibecoding/claudecode-session-continuity
cd claudecode-session-continuity
./install.sh
```

The installer:
1. Copies two hooks to `~/.claude/hooks/`
2. Copies two skills to `~/.claude/skills/`
3. Patches `~/.claude/settings.json` (idempotent — safe to re-run)

That's it. No API key. No config file. No daemon.

---

## What it does

### `/s` — quick-save

In any Claude Code session, type `/s`. A background Haiku agent reads the transcript and writes a structured summary to `~/.claude/projects/<project>/memory/convo_YYYY-MM-DD_<topic>.md`.

Output template (adopted from hermes-agent):

```
## Active Task
<what's in progress at save time>

## Resolved
<what got done this session>

## Pending User Asks
<unanswered questions, numbered>

## Remaining Work
<concrete next steps>

## State Deltas
<enabled/disabled/param changes>

## Pivots
<position flips during session>
```

Hard 3KB cap per file. Forces the agent to compress, not dump.

### `/crash` — bulk recovery

If Claude crashed, your laptop died, or you force-quit five terminals in a row — `/crash` scans today's JSONLs, diffs against already-saved summaries, and saves any orphans. One agent handles the batch.

### Deferred-save — the auto-layer

Two hooks give you automatic coverage for the cases you'd otherwise forget:

```
/clear or close terminal
    ↓
SessionEnd hook writes marker to /tmp/pending_saves/<session_id>.json
    ↓
Next Claude Code session, first user prompt
    ↓
UserPromptSubmit hook reads queue, injects a nudge
    ↓
Claude spawns a background save Agent → deletes marker
    ↓
~20 seconds later: your prior session is saved
```

Coverage:
- `/clear` — ✅ covered (SessionEnd fires cleanly)
- Graceful terminal close (`/exit`, Cmd+W confirmed) — ✅ covered
- Hard kill (SIGKILL, OOM, power loss) — ❌ not covered — use `/crash` for these

Works across terminals: close a window in Project A, the save fires next time you open Claude Code in Project B.

---

## Why structured template?

Most save-your-session tools produce freeform bullets that get worse every session (context dumping, no signal-to-noise discipline). The structured template forces each save to answer the same five questions — making the memory actually useful when you (or another Claude session) reads it back later. Uniform format also means an LLM can grep or embed across 100 convos without getting confused by varying shapes.

Hermes-agent uses the same pattern for its in-context compaction handoff. Stealing it for session saves gets you the same benefit at the checkpoint level.

---

## Configuration

### Skip specific project directories (optional)

If you have Claude Code subprocesses running inside bots or agents (e.g. a Telegram bot that spawns Claude SDK), you don't want their SessionEnd events to pollute your save queue. Export a colon-separated skip list:

```bash
export SESSION_CONTINUITY_SKIP_CWDS='telegram-bot:admin-bot'
```

Any `cwd` containing one of those substrings will be skipped.

### Memory location

Saves go to `~/.claude/projects/<project-slug>/memory/` where `project-slug` matches the directory Claude Code uses for transcripts. This keeps saves local to each project — no cross-project pollution.

---

## How it compares

| | Manual `/save` skills | This | hermes-agent |
|---|---|---|---|
| Save trigger | manual only | manual + auto-deferred | auto-writes to SQLite |
| Recovery after crash | manual grep | `/crash` | sessions always queryable |
| Template | freeform | **structured (Active/Resolved/Pending/Remaining)** | structured |
| API cost | 0 | 0 | 0 (or configurable provider) |
| Graph / wiki integration | no | pair with [memory-wiki-graph-stack](https://github.com/nardovibecoding/memory-wiki-graph-stack) | no (external plugins) |

---

## License

MIT. See LICENSE.

---

## Credits

- Structured template pattern from [hermes-agent](https://github.com/nousresearch/hermes-agent) by Nous Research
- Built with [Claude Code](https://claude.com/claude-code)
