# Security Policy

## Supported Versions

The `main` branch is the supported public template.

## Reporting A Vulnerability

Open a private GitHub security advisory for vulnerabilities. Do not publish raw
session transcripts, token examples, or local recovery files in public issues.

## Local State

Saved summaries live under `~/.claude/projects/<project-slug>/memory/`.
Deferred-save markers live under `/tmp/pending_saves/<session_id>.json`.

Treat both locations as local runtime state. Do not commit raw transcripts,
pending-save markers, recovered session data, or machine-specific project paths.
