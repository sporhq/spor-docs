---
title: Lenses, program view, and workflows
description: Saved views as nodes, the auto-derived progress tree over blocks topology, and proposal-gated workflow DAGs.
sidebar:
  order: 7
---

**Use this when** you are building saved views or a team dashboard, asking
where a whole workstream stands, or defining repeatable automation whose
runs are tracked on the graph.

**You do not need this if** the queue and briefings answer your day-to-day
questions; these are surfaces layered on top, and [The decision
queue](/use-spor/queue/) is the beginner path.

**After reading this, you should be able to** choose between a lens, program
view, and workflow, read a lens's query and render blocks, and explain how
workflow steps are claimed.

Three surfaces turn the graph into something you can look at and act
through: lenses (saved views), the program view (an auto-derived progress
tree), and workflows (reviewable automation DAGs with tracked runs).

## Lenses: saved views as nodes

A lens is a `lens-` node whose body carries fenced blocks — the view
definition is data in the graph, versioned and shareable like everything
else:

````markdown
---
id: lens-tidefall-retry-radar
type: lens
repo: billing
title: Retry rollout radar
summary: Open work gating the billing retry rollout, grouped by status.
status: active
date: 2026-06-05
---

What still gates the rollout, at a glance.

## query

```json
{ "traverse": { "from": "task-tidefall-retry-rollout", "follow": ["blocks"],
  "direction": "in", "depth": 2 } }
```

## render

```json
{ "as": "board", "group": "status" }
```
````

The `## query` block selects and traverses; `## render` chooses the shape
(`list`, `table`, `tree`, `board`); an optional `## actions` block declares
write affordances bound to registry transitions (a "close" button is a
declarative status change, gated exactly like any other write); and an
optional `## custom` block is a sandboxed render function for the rare view
the declarative catalog cannot express. The JSON blocks are data — you can
ask "which lenses select on this status?" — and running a lens is a pure
function of the graph snapshot, so the same graph renders the same bytes.

Render a lens with `spor lens <id>`, the `render_lens` MCP tool (calling it
with no id lists the catalog), or in a browser via the server's render
route. A read-only, expiring share link can be minted for teammates without
a checkout (`spor share <lens-id>`); a shared link never carries a
write-capable credential.

A `workspace-` node composes several lenses into one layout — a `## layout`
block naming lens slots — and renders as a single view tree, so a team
dashboard is itself a node.

## The program view: progress from blocks topology

For "where does the workstream stand?", no lens authoring is needed. Given
any root node — an umbrella task, a milestone, anything other work
`blocks` or [`member-of-program`](/reference/graph-model/edges/) — the
program view walks that root's members and derives each one's bucket from
the same truth the queue uses:

- **done** — terminal status, superseded, or retired by a live
  `resolves`/`answers` edge (counted even while the status field lags);
- **blocked** — live but gated by its own live unresolved blockers;
- **active** — live, unblocked, started;
- **open** — live, unblocked, not started.

The result is a progress bar plus a gating tree. Shared blockers render once
and repeat as marked leaves, counted once; depth and size caps report what
they skipped rather than truncating silently. A root with no members at all
is a successful empty result telling you how to model the program: add
`blocks` and/or `member-of-program` edges from the member work.

Membership and gating are independent facts about a member. `blocks` keeps
meaning only gating; a dedicated `member-of-program` edge (member ->
umbrella) records pure topology instead, so a member that doesn't gate the
umbrella, or a gating prerequisite that isn't really part of the program,
can be told apart — see [Edge types](/reference/graph-model/edges/) for the
full semantics. The view prefers `member-of-program` **per node**: a root
with any inbound `member-of-program` edges takes those as its members; a
root with none still falls back to inbound `blocks`, so an unmigrated
program renders exactly as before. `member-of-program` ships as a
graph-resident schema pending activation in a given graph — `spor schema
member-of-program` shows whether it's live yet.

## Workflows: automation as reviewable nodes

A `wf-` node defines a repeatable automation as a DAG of steps, carried as a
fenced JSON block (inputs, steps, concurrency) with an optional sandboxed
routing function. Because a workflow is a node, it is versioned, attributed,
and reviewed like everything else — and it is proposal-gated: created
through the server it lands as `proposed` and inert, and a **different
identity** must activate it. An agent may author a workflow; it may not
deploy one.

Each execution is a `run-` node (`performs → wf-...`) recording state and
lineage; `triggered-by` records what set it off. Starting a run
(`spor run <workflow-id>` or the `run_workflow` MCP tool) only creates the
run: workers — anything with a token — then claim ready steps over the claim
API, do the work, and report a verdict. Step claims are leases like
[task claims](/reference/graph-model/claims/): an expired lease frees the step, and a
stale worker's late report conflicts instead of overwriting the recorded
outcome. Approval steps are excluded from worker-claimable work; they
surface in the decision queue for a person. Live runs that get stuck surface
in the queue too.

Run nodes are engine-managed: their state can only advance through the run
engine's claim/complete path, so a step cannot be hand-flipped to succeeded
through the ordinary write API.
