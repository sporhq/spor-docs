---
title: Writes
description: Write semantics, node puts, edges, status, priority, commits, capture, corrections, and questions.
sidebar:
  order: 4
---

Every mutation is validated, attributed, serialized, and committed to the
graph's version history. These semantics apply to every write endpoint below
(and identically to the MCP tools — the two surfaces share one core).

## Write semantics

- **Attribution.** The server stamps `author: <identity>` and
  `authored_via: mcp|rest|capture|dispatch` from the authenticated token; any
  `author:` supplied in the payload is discarded. A write under an
  agent-scoped token additionally stamps `authored_by_agent` and `session`
  and uses `authored_via: dispatch`, while `author:` stays the agent's owning
  person — the node reads "agent on behalf of person". These ride-along
  fields are token-derived too.
- **Create.** `if_exists: "skip"` reports an id collision as `skipped`;
  `if_exists: "error"` makes it a `conflict` error.
- **Update.** The caller must send `revision` — the identifier of the version
  it read (returned by node reads). A mismatch is a `409 conflict` carrying
  the current revision; re-read and retry. No silent last-write-wins.
- **Validation.** Id/filename agreement, kebab-case, type prefix, a mandatory
  standalone summary, known node type, date format, edge syntax. Failures
  return the validator's error list verbatim so a calling model can
  self-correct. Size limits: body ≤ 8 KB, summary ≤ 500 characters, ≤ 40
  edges per node.
- **Edge normalization.** Edge types accept canonical names,
  registry-declared aliases, and inverse labels — an edge written from the
  target's side (`{blocked-by, to: X}` on N) is flipped and written to X as
  `{blocks, to: N}`, reported in `warnings`; the target must exist. Unknown
  edge types beyond that vocabulary are rejected, not defaulted. Edges to
  nonexistent ids are allowed on full puts (they mark nodes worth creating).
- **Schema gating.** The active schema's transition hooks arbitrate updates —
  a denial is `409 transition_denied` with the schema's reason. Schema nodes
  created through the server are forced to `status: proposed`; flipping one
  `proposed → active` requires an identity different from the proposal's last
  author (the self-approval ban).
- **Success shape.** Writes return `{status, id, revision, warnings}` with
  `status: created|updated|skipped`.

## POST /v1/digest

A read that shares the compile pipeline: digest-mode context for a prompt.

```json
{ "query": "how do we throttle the public API?",
  "project": "billing",
  "min_sim": 0.08 }
```

Returns `{found, text}`; `found: false` is a successful empty result, not an
error. `root` (e.g. `"root": "task-api-rate-limits"`) is the structural-walk
twin of `query` — pass one or the other; the two are mutually exclusive,
`root` wins if both are sent, and an unknown root id is `422`. Optional `project`
scopes the compile to the session's project (same-project relevance boost,
grouping union, always-on norms), resolving the slug through project aliases;
a bad slug is `422`. Omitting `project` runs the digest project-blind, so
older clients sending only `{query}` are unaffected.

## POST /v1/nodes

Put nodes, batch. Entries may be raw markdown strings or
`{node, if_exists, revision}` objects:

```json
{ "nodes": ["<full markdown file content, frontmatter + body>"],
  "if_exists": "skip" }
```

Returns `{results: [...]}` — HTTP 207 when any entry failed. Entries are
applied **sequentially** and each is fully validated before the next,
including the completion-resolver gate that runs on create: a born-terminal
node (a `done` task, a `resolved` issue) must have its resolving
decision/artifact **earlier in the same batch** (resolver-first ordering; the
gate is not deferred to end-of-batch). The 207 is partial success — entries
already applied before a later failure are not rolled back.

```bash
curl -s https://api.sporhq.io/v1/nodes \
  -H "Authorization: Bearer $SPOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"nodes": ["---\nid: task-api-rate-limits\ntype: task\n..."], "if_exists": "skip"}'
```

## POST /v1/nodes/{id}/edges

Add one typed edge — normalize/flip, dedupe, append; no revision echo needed:

```json
{ "type": "blocks", "to": "task-api-rate-limits",
  "attrs": { "profile": "gpu-box" } }
```

Returns `{status: "updated"|"skipped", id, revision, warnings}` — `skipped`
means the edge was already present (the call is idempotent), and `id` is the
node actually modified (an inverse form writes to the other node). Both nodes
must exist.

Optional `attrs` carries trailing flat edge attributes (values are simple
`[A-Za-z0-9_-]` tokens; `type`/`to` are reserved; richer values need a full
node put). With `attrs`, a duplicate `(type, to)` becomes an **upsert**: same
attributes still `skipped`, different attributes replace the edge's attribute
set (not merged). Omitting `attrs` never touches an existing edge's
attributes.

**Submitting a review is one call.** The review-outcome edges
(`review-requested`, `reviewed-by`, `changes-requested-by`, plus the
`approved-by` approval synonym) are mutually exclusive per `(node, person)` —
the edge type *is* the reviewer's current verdict. Adding one review edge
flips any sibling review edge to that same person in place, reported in
`warnings` (`flipped review-requested -> reviewed-by for <person>`). The flip
is scoped strictly to the review family; every other edge type keeps plain
append-or-idempotent behavior.

## DELETE /v1/nodes/{id}/edges

The withdrawal twin: drop one typed edge by `{type, to}`, normalized exactly
as the add (an inverse form removes the canonical edge on the other node and
echoes its id). A missing edge is an idempotent `skipped`, never an error.
Use it when a relationship should cease to exist — a withdrawn review
request, a dismissed review — which the review flip cannot express (the flip
only swaps one verdict for another; it never drops an edge).

## POST /v1/nodes/{id}/status

One-scalar status update through the schema's transition gate:

```json
{ "status": "done" }
```

A denial is `409 transition_denied` with the gate's reason, exactly as on a
full put. Setting a work node to an in-progress status also **claims** it —
the same lease as [`/claim`](/reference/api/leases/). Setting a `type: schema` node's
status is how a human flips `proposed → active`.

## POST /v1/nodes/{id}/priority

The human-override half of the queue: `{"priority": "p1"}` where the value is
`p1` (highest), `p2`, `p3`, or a clearing form (`none`/`clear`/`""`/`p0`).
Server-side read-modify-write, no revision round-trip. Stamps `priority_by`
(acting identity), `priority_at`, and `priority_via` (the surface), so an
agent-set priority is distinguishable from human triage. An unknown value is
`invalid_node` with the allowed list in `details`.

## POST /v1/nodes/{id}/commits

Link a code commit to a node: `{"repo": "billing-service", "sha": "8f3a2c1"}`
appends `repo@sha` to the node's `commits:` list. The repo slug is
kebab-case; the sha is 7–40 lowercase hex; at most 40 commits per node.
Idempotent, with prefix-aware dedup. The reverse lookup is
`GET /v1/commits/{sha}` on [Reads](/reference/api/reads/).

## POST /v1/capture

Raw text in, typed nodes out — the default write door for sessions:

```json
{ "text": "We chose fixed-window rate limiting for the public API; sliding-window cost too much memory at the edge.",
  "context": { "project": "billing", "during": "task-api-rate-limits" },
  "idempotency_key": "9f2c47d0-5b1e-4c8a-a7e3-2d6f8b41c9aa" }
```

The server-side ingestion model drafts node(s) against the live schema
registry; the deterministic half validates (one self-correction bounce),
normalizes, stamps `authored_via: capture`, and commits. Returns
`{status, ids, nodes, summary, warnings}`. A `pending` status means the text
fit no schema (or failed validation twice) and was preserved as a
capture-pending node — ingestion-quality failures never lose text. Only an
unreachable ingestion model is an error (`503 ingestion_unavailable`).

- **Idempotency.** `idempotency_key` (client-generated; equivalently the
  `Idempotency-Key` header) guards the whole capture against the
  timeout-then-server-completes race: a key the server has already seen
  returns the original result instead of re-ingesting, so a client that
  aborted at its read timeout does not double-write on replay. Putting the
  key in the body means a verbatim replay of a spooled request carries it
  for free.
- **Cross-project dependencies.** `context.blocks` (a node id, must exist)
  and `context.needed_by` (`YYYY-MM-DD`) declare a dependency: set
  `context.project` to the serving project and the server attaches a
  `blocks` edge to the requester plus the deadline deterministically, not via
  the model. A missing `blocks` target is `404`; a non-date `needed_by` is
  `422` — both rejected before any model call.
- `source: "distill"` marks backstop captures in the journal.

## POST /v1/distill/report

Sweep telemetry, journal-only — no graph mutation: `{facts, captured?,
spooled?, rejected?, project?, session?}` returns `{status: "reported"}`.
Zero-fact sweeps report too.

## POST /v1/corrections

Propose a standing correction to briefing compiles:

```json
{ "target": "task-api-rate-limits",
  "pin": ["dec-fixed-window-rate-limit"],
  "exclude": ["art-stale-benchmarks"],
  "guidance": "The edge cache was replaced in Q2; ignore pre-Q2 latency numbers.",
  "title": "Pin the rate-limit decision" }
```

Returns 201 `{status, id, revision, warnings}`. The server generates the
correction node's id and routes it through the standard write path. `target`
is one of: an existing **node id** (fires when that node is the compile root
or a query-matched seed), **`project:<slug>`** (fires on every compile for
that project, slug resolved through aliases), or **`global`** (every compile,
graph-wide). A node-id target must exist; the `project:`/`global` forms are
accepted verbatim.

## POST /v1/questions

File a question the graph could not answer:

```json
{ "text": "Which regions is the rate limiter deployed to?",
  "title": "Rate-limiter regions",
  "mentions": ["task-api-rate-limits"] }
```

Returns 201 `{status, id, project, routed_to, via, asker, revision,
warnings}`. The question becomes a durable node, deterministically routed to
the steward of the closest relevance-neighborhood node (unrouted if none
matches), and joins the decision queue until answered — answering means
writing a node with an `answers` edge to it. The project is derived from the
relevance neighborhood, then the asker's home project, unless an explicit
`project` slug overrides it (pass one for a mention-less question); a
malformed slug is `400`.

## POST /v1/gardener

Run a maintenance sweep now; findings are filed as queue items. Returns
`{checked, filed, resolved, skipped, generated_at}` (`filed`/`resolved`/
`skipped` are id lists, `checked` a count). Authenticated but not admin-gated
today — any valid team token can trigger it.
