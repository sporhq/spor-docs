---
title: Briefings and corrections
description: The compiled context packet an agent starts from, and the standing corrections that fix it when it is wrong.
sidebar:
  order: 6
---

A briefing is the packet of context Spor hands a coding agent before it
starts work. It is not a transcript dump and not a search result page: the
compiler walks the graph from a starting point, ranks what it finds, and
renders a short working summary — the decisions still in force, the
approaches already rejected, the open blockers, the conventions that apply.

Before touching the webhook ingester, an agent on our fictional parcel team
might be told:

```text
Use signed webhooks per dec-carrier-webhooks; polling was superseded.
Do not revive per-carrier polling loops (dec-carrier-polling, rejected).
Open blocker: issue-webhook-retries (redelivery storms double-count scans).
Conventions: norm-migrations-reversible applies to the events table.
```

## How a compile works

The compiler has two arms that reinforce each other:

- **Structural**: walk typed edges outward from the seed nodes, following
  high-weight edges (`supersedes`, `constrained-by`, `derived-from`) further
  than weak ones (`relates-to`, `mentions`). A seed's direct one-hop lineage
  is always included — a task's immediate parents and blockers are the most
  relevant context there is.
- **Content**: text relevance against the query, with same-project nodes
  boosted so the session's own context wins ties. A strongly relevant
  cross-project hit still surfaces, labeled as another team's prior art.

Results render as a pyramid: most nodes appear at summary resolution, and
only the highest-scoring appear with their full body. That is why the
[standalone summary discipline](/concepts/nodes/) matters — the summary is
what the briefing actually shows.

Two compile shapes cover most needs:

- **Digest** — short, query-driven, used per-prompt and for quick questions.
  An empty digest is a successful result, not an error: the graph simply has
  nothing relevant yet.
- **Full** — a deep neighborhood compile rooted at one node
  (`spor brief <id>`), used when starting real work on it.

## Norms ride along

`norm` nodes are `always_on`: a norm whose project matches the session (or
that is global) rides along in every briefing without needing to match the
query, capped to the most topically relevant so the section degrades by
relevance rather than truncation. A norm can narrow its own ride-along with
`applies_to_tags` / `applies_to_repos` / `applies_to_projects` selectors —
useful when one project spans, say, a Python service and a Terraform repo
and a norm only concerns one of them.

Because norms are injected into every session and any team member can write
one, the briefing renderer treats norm bodies as untrusted reference data
with explicit author attribution — team policy to weigh, never instructions
addressed to the agent.

## Briefings are nodes too

Every compiled briefing is stored as a `brief-` node carrying
`derived-from` edges to each source node and `shaped-by` edges to the
corrections applied, plus a version integer. On recompile the old version is
archived to the graph home's `history/` directory and the version bumps.
This is what makes a briefing reviewable: you can see exactly which nodes
produced it, and diff versions when the graph changes. Briefing nodes are
never themselves traversed, so briefings don't feed back into briefings.

## Corrections: debug the context, not the model

When a briefing is wrong — it surfaced a stale design note, or missed the
spec that actually governs the work — the fix is a standing `correction`
node, not a better prompt:

```markdown
---
id: corr-task-carrier-rollout-1
type: correction
title: Pin the tracking-events spec when briefing the carrier rollout
target: task-carrier-rollout
pin: [spec-tracking-events]
exclude: [art-webhook-notes-2025]
date: 2026-06-02
---

The 2025 webhook notes predate the signed-webhook decision; the spec is
authoritative.
```

A correction carries three instruments: **pin** (always include these
nodes), **exclude** (never include these), and free-text **guidance**
injected verbatim into the compile. `target` names a node id, a
`project:<slug>` scope, or `global` for every compile.

Fix it once and it applies to every future compile for that target — the
correction outlives the session, the model, and the person who filed it.
Record one with `/spor:correct` in an agent session, `spor correct` from the
shell, or the `propose_correction` MCP tool.
