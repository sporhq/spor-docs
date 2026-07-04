---
title: Tool reference
description: Every Spor MCP tool — purpose, key parameters, and when to reach for it.
sidebar:
  order: 3
---

All twenty-three tools, grouped by role in the
[operating loop](/reference/mcp/operating-loop/): reading and orienting, views,
writing, claiming, and asking. Every tool returns both human-readable text and
structured JSON. Writes follow one set of semantics: validated against the
live schema registry, attributed from your token (any supplied `author:` is
discarded), and committed to the graph's history. Validation failures return
the validator's error list verbatim, so a calling model can self-correct.

Example ids throughout are fictional.

## Reading and orienting

### `query_graph`

Search the graph, or compile one node's neighborhood.

| Parameter | Meaning |
| --- | --- |
| `query` | free text — the task, question, or prompt |
| `root_id` | optional node id; overrides `query` and compiles that node's neighborhood instead |
| `mode` | `digest` (default) or `full` |
| `min_sim` | optional relevance gate |

Returns `{found, text, node_ids, top_sim}`. `found: false` means the
relevance gate was not met — a successful empty result, not an error.

Reach for it twice per task: free-text first ("what do we know about retry
backoff?"), then with `root_id` on each interesting id it surfaces. The
`root_id` form is the recursive-deepen move — neighbor to neighbor until you
have enough context.

### `get_node`

One node in full: raw markdown, parsed frontmatter, edges, and `revision`
(the git blob SHA you must echo back to update the node). Input `{id}`;
unknown ids are a not-found error. The node's schema may attach derived
context as extra top-level keys — for example `resolution`, what resolved or
answered this node. Extra keys are additive; ignore what you don't know.

Reach for it when you need the exact text or are about to update the node.
Trust inbound `resolves`/`answers` edges over the `status` field.

### `node_history`

One node's commit lineage — a `git log` projection over its file. Input
`{id, sha?, limit?}`: without `sha` you get the chain of revisions (newest
first, each with `sha`, actor, date, and message, and an `internal` flag that
marks server-internal writes apart from real edits); with `sha` you get that
one revision's detail — the change type, the patch it introduced, and the full
node content at that point. `limit` defaults to 50 (max 200).

Reach for it to see who changed a node and why over time — the frontmatter
`author` only records the last editor, so this is the durable record of the
whole chain.

### `show_queue`

The ranked decision queue — the data answer to "what's next", "show my
queue", "the backlog".

| Parameter | Meaning |
| --- | --- |
| `project` | scope to one project slug |
| `types` / `exclude_types` | whitelist / blacklist of node types (exclude wins on overlap) |
| `assignee` | a person id, or `"me"` — see below |
| `limit` | page size, default 20, max 100 (clamped) |
| `offset` | items to skip in the ranked order |

Each item carries id, title, type, status, priority, score, its ranking
signals (blocking, heat, staleness, age), a suggestion (`do` or `close`), and
a one-line *why*. Items retired by a live inbound `resolves`/`answers` edge
are excluded whatever their status field says. Alongside the items ride open
gardener findings, pending captures, questions you asked, and nodes whose
review is requested of you.

The aggregate counts always cover the full ranked set regardless of the
page, so one call answers "how many issues vs tasks". Pagination is an offset
over a point-in-time ranked slice, not a cursor: the queue re-ranks on every
call, so across a re-rank an item may repeat or be skipped once — never a
hard error. Walk the whole queue with `offset = next_offset` until it comes
back null.

`assignee` is a **narrower carrying view** — the union of nodes assigned to
that person and nodes they steward. For the ordinary "my queue" answer, omit
it.

### `recent_changes`

The team's recent-activity feed — the temporal entry point (`query_graph` is
semantic, `show_queue` is forward-looking, `render_lens` is current state).
Input `{since?, project?, limit?}`, where `since` is a commit SHA (7–40 hex)
or a date phrase git understands (`"12 hours ago"`, `"2026-06-15"`); omitted,
you get the most recent changes. Each entry carries the node's current
`authored_via` — machine-written (`capture`/`distill`/`gardener`) versus
human — the trust signal a rendered digest hides.

Reach for it for "what did the agents write overnight" or "what landed since
that commit". It returns the changed nodes as data; the model writes the
prose summary.

### `analytics`

Work-flow analytics over the team graph: weekly created / completed / net /
open-backlog cohorts, throughput, cycle-time median and p90, current WIP by
node type, and the oldest-open bottlenecks. Input
`{project?, types?, weeks?, top?, aging?}`. Completion is measured at the
node's status-*transition* time, never its last update, so a later edge
append can't corrupt the "completed last week" signal.

Reach for it for the created-vs-completed view when you can't run the CLI —
the remote twin of local analytics.

### `schema`

Introspect the live schema registry — the contract as data. With no
arguments it returns the full snapshot: node types, edge types, queue policy,
policies, registers, with each entry tagged by `source` (seed, graph, or
native). `{type}` narrows to one node or edge type; `{code: true}` embeds
each hook's source.

Reach for it instead of guessing the vocabulary: an organization's schema can
add node and edge types, and this reflects what is actually live.

## Views

Three tools whose results carry a view tree; on MCP-Apps hosts they attach
the [interactive widget](/reference/mcp/widget/), elsewhere the same view renders as
text.

### `render_queue`

The widget twin of [`show_queue`](#show_queue): same input, same queue, same
ranking, filters, and pagination — it exists only to make widget attachment
an explicit choice. Use `show_queue` when you just need the answer;
`render_queue` when the user should get the interactive queue.

### `render_lens`

Run a saved lens — a named, versioned view over the live graph: a board, a
table, a lineage tree. Input `{lens_id, params?}`, where `params` fills the
lens's declared parameters (a project, a focus node). Returns the view tree
plus the ids it covered.

`lens_id` is optional: call with no `lens_id` to get the **lens catalog** —
the discovery step before rendering. An unknown `lens_id` errors but still
carries the catalog. A lineage lens is the fast way to see why one node
exists and what it depends on.

### `render_program`

The birds-eye "where do we stand" for a large workstream, derived on demand
from `blocks` topology — no lens authoring needed. Input
`{id, max_depth?, max_nodes?}` where `id` is a root node other work blocks
(an umbrella task, a milestone). The server walks everything that
transitively blocks it and buckets each node from the same truth the queue
uses: **done** (terminal status, superseded, or retired by a live
`resolves`/`answers` edge — even while the status field lags), **blocked**
(gated by its own live blockers), and live unblocked work split **active**
vs **open**. Returns a progress summary (totals and percent) plus the gating
tree; shared blockers render once and repeat as marked leaves, and depth or
node caps report what they skipped — never silently.

A root that nothing blocks is a successful empty result telling you how to
model the program (add `blocks` edges from the gating tasks).

## Writing

### `capture`

The default write door: raw text in, typed nodes out. Input:

| Parameter | Meaning |
| --- | --- |
| `text` | 2–3 standalone sentences — the fact, what and why |
| `project` | optional project slug |
| `during` | optional node id the work was discovered during (provenance) |
| `blocks` | optional node id this work blocks — declares a cross-project dependency (the target must exist) |
| `needed_by` | optional `YYYY-MM-DD` deadline that ramps the item's queue urgency as it nears |

The server drafts node(s) against the live registry, validates, links, and
commits. Output is `captured` — or `pending`, meaning the text fit no schema
and was preserved as a capture-pending node for triage; quality failures
never lose text.

Reach for it first when you are unsure what shape the outcome should take.
Use the precise tools below when you know exactly the node or edge you mean.

### `put_node`

Create or update one node from its full markdown (frontmatter + body).

| Parameter | Meaning |
| --- | --- |
| `node` | the complete markdown file content |
| `if_exists` | `skip`, `error` (default), or `update` |
| `revision` | the blob SHA from `get_node` — required for `update`; a mismatch is a `conflict`, re-read and retry |

Limits: body ≤ 8 KB, summary ≤ 500 chars, ≤ 40 edges. The tool's own
description embeds the registry's full edge vocabulary — canonical types,
aliases, and inverse forms — generated from the live registry, so an org
schema change shows up without a deploy. Edges may point at ids that don't
exist yet on a full put; they mark nodes worth creating.

### `add_edge`

Add one typed edge: `{id, type, to, attrs?}`. Accepts canonical, alias, and
inverse forms — an inverse (`blocked-by`) is flipped and written on the other
node. Idempotent: an already-present edge is `skipped`. No revision echo
needed. `attrs` carries flat edge attributes (simple tokens only); with
`attrs`, re-adding an existing edge replaces its attribute set in place.

One special case: the review-outcome edges (`review-requested`,
`reviewed-by`, `changes-requested-by`, and the `approved-by` synonym) are
mutually exclusive per (node, person) — adding one **flips** any sibling
review edge to that person in place, so submitting a review verdict is a
single `add_edge`. Every other edge type keeps plain append-or-skip
behavior.

This is the closing move of the loop: `add_edge {id: "dec-tidefall-idempotency-keys",
type: "resolves", to: "issue-tidefall-double-charge"}` retires the issue.

### `remove_edge`

The withdrawal twin of `add_edge`: `{id, type, to}`, same form normalization,
and a missing edge is an idempotent `skipped`, never an error. Use it when a
relationship should cease to exist — a withdrawn review request, a dismissed
review — which the review flip can't express (the flip only swaps one verdict
for another; it never drops an edge).

### `set_status`

Change one node's status: `{id, status}`. The active schema's transition
gate arbitrates; a denial returns `transition_denied` with the gate's reason,
exactly as on a full put. No revision round-trip needed. On a `type: schema`
node, this is how a human flips `proposed → active` — subject to the
self-approval ban (the approver must differ from the proposal's last author).

### `set_priority`

The human-override half of queue ranking: `{id, priority}` with `p1`
(highest), `p2`, `p3`, or a clearing form (`none`, `clear`, `""`, `p0`). It
stamps who set it, when, and through which door, so an agent-set priority is
always distinguishable from human triage. An unknown value errors with the
allowed list.

### `propose_correction`

Sugar over `put_node` for correcting future briefings — debug the context,
not the model.

| Parameter | Meaning |
| --- | --- |
| `target` | a node id, `project:<slug>`, or `global` — where the correction fires |
| `pin` | node ids to always include |
| `exclude` | node ids to keep out |
| `guidance` | free text injected into compiles for the target |
| `title` | one line |

A node-id target fires when that node roots or seeds a compile; `project:`
fires on every compile for that project; `global` fires graph-wide. Reach for
it when a briefing was wrong, missed something, or kept surfacing something
stale — the correction persists where a chat instruction would not.

### `ask_question`

File a question the graph could not answer: `{text, title?, mentions?,
project?}`. The question becomes a durable node, deterministically routed to
the steward of the closest relevant node (routing considers `mentions`
first), and joins the decision queue until answered. Answer it by writing a
node with an `answers` edge to the question.

The question's project is derived from its neighborhood by default; pass
`project` explicitly for a mention-less question whose neighborhood would
yield nothing.

### `run_workflow`

Start a run of an **active** workflow by hand: `{workflow_id, inputs?}`.
Creates a workflow-run node with lineage and returns the run id and initial
step states. A proposed workflow must first be activated by a different
identity (the self-approval ban). This tool only starts the run — workers
claim and execute the steps; it never executes effects itself.

## Claims and leases

Team coordination primitives: taking a piece of work so two people don't do
it at once. A claim is a heartbeat-renewed **lease** plus a durable `assigned`
edge; the claimer is always `$viewer` from your token, never an argument. A
live lease held by someone else is a `conflict` that names the holder and when
it expires.

### `claim`

Take the lease on a node: `{id, session?}`. Writes the `assigned` edge once
and creates the lease. Re-claiming your own live claim just renews it;
claiming one someone else holds is a `conflict`. `session` scopes the
heartbeat to one run — omit it and any of your sessions may renew.

### `renew`

The heartbeat that keeps a claim from lapsing: `{id, session?}` bumps your
live lease's expiry with no commit. A lapsed or stolen lease is a `conflict`
naming the current holder.

### `extend`

Manually stretch your live lease for a known long idle gap: `{id, ms}`,
extending it by `ms` milliseconds. Bounded by the org's maximum lease policy
(a request past the ceiling caps to it); it never shortens a lease.

### `release`

Drop the lease and retire the `assigned` edge, returning the node to the pool:
`{id}`. Idempotent — releasing a node you hold no lease on still succeeds and
cleans up any lingering `assigned` edge of yours; releasing a claim someone
else holds is a `conflict`.
