---
title: Review what changed
description: Catch up on recent graph activity, follow one node's history, trace a commit back to its reasons, and read a program view.
sidebar:
  order: 6
---

Use these read paths when you return to work and need to see what moved. They
cover the recent activity feed, one node's edit history, a commit's graph
references, and the status of a whole workstream.

## Recent changes

`spor changes` shows recent graph activity: one entry per node, newest change
in range first.

```sh
spor changes --since '12 hours ago' --project billing
```

Each entry is tagged as human-written or machine-written, with machine sources
such as capture, distill, and the gardener. That makes the feed useful after
agents worked overnight.

`--since` accepts a commit sha or any date or relative phrase git understands,
such as `'12 hours ago'` or `2026-06-15`.

The full CLI entry is in
[Reading the graph](/reference/cli/reading-the-graph/#changes). From MCP, use
the `recent_changes` tool.

## One node's history

`spor history <id>` shows the commit history for one node: who edited it,
when, and what changed.

```sh
spor history dec-tidefall-billing-retries --limit 10
```

Pass a revision sha to show that revision's diff and change type. Add
`--content` when you also need the full node at that revision.

History matters because the visible `author` field in node frontmatter
re-stamps to the last editor on every write. Git history is the durable record
of the full chain of editors.

The full CLI entry is in
[Reading the graph](/reference/cli/reading-the-graph/#history). From MCP, use
the `node_history` tool.

## From commit to reasons

`spor blame <sha>` reverse-lookups a git commit to the decision, task, and
issue nodes that reference it in their `commits:` field.

```sh
spor blame 4f2a91c --repo billing
```

Use it after ordinary git blame: blame a line, then ask Spor why that commit
exists. The sha can be abbreviated or full, from 7 to 40 hex characters, and
matching is prefix-aware. An empty result is normal for a commit linked to no
node, and exits 0.

The `commits:` field is populated automatically when Spor is wired into a
coding agent. A hook watches for commits made during a session and links them
to related nodes, so nobody annotates commits by hand. See
[What happens automatically](/use-spor/what-happens-automatically/) for the
hook path.

The full CLI entry is in
[Reading the graph](/reference/cli/reading-the-graph/#blame).

## Program view

For a whole workstream, use the program view. There is no CLI verb for it; the
view is served by the [`render_program` MCP tool](/reference/mcp/tools/#render_program)
with `{id, max_depth?, max_nodes?}` and by
[`GET /v1/program/{id}`](/reference/api/reads/). On MCP-Apps-capable hosts, it
renders as an interactive view.

Start from a root node that other work `blocks`, such as an umbrella task or a
milestone. The server walks everything that transitively blocks the root and
buckets each node from the same truth the queue uses:

- **done** — terminal status, superseded, or retired by a live `resolves` or
  `answers` edge. This counts even while the status field lags.
- **blocked** — gated by the node's own live blockers.
- **active** — live, unblocked, and started.
- **open** — live, unblocked, and not started.

The result includes progress totals, percent complete, and the gating tree.
Shared blockers render once and repeat as marked leaves. If depth or node caps
skip anything, the response reports what it skipped.

A root that nothing blocks is a successful empty result. It means the program
needs modeling: add `blocks` edges from the work that gates it.

For example, the tidefall team hangs the billing retry-flow rollout under
`task-tidefall-retry-rollout`. Member tasks such as
`task-tidefall-retry-emails` carry `blocks` edges to that umbrella task. The
program view of `task-tidefall-retry-rollout` shows how far the rollout has
moved.

See [the queue](/use-spor/queue/) for the status rules the view reuses, and
[Lenses, program view, and workflows](/reference/graph-model/lenses-and-workflows/)
for the model. Use lenses when you need a saved view rather than a program
progress tree.
