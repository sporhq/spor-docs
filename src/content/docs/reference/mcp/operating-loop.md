---
title: The operating loop
description: ORIENT, TRAVERSE, COMMIT — the mental model the Spor server teaches a connected assistant.
sidebar:
  order: 2
---

The server does not present its tools as a flat list. Its MCP instructions —
the block a host surfaces to the model on connect — frame them as a loop:
**ORIENT** (find where to start), **TRAVERSE** (gather context until you have
enough), **COMMIT** (write the outcome back so the next session inherits it).
There is no ambient context on the MCP surface; nothing arrives unless the
assistant asks, so the loop is what keeps a session grounded in what the team
already knows.

## ORIENT — find where to start

Two entry points, depending on the question:

- **`query_graph` with free text** — "what does the graph already know about
  this task?" Call it before designing or deciding anything non-trivial. An
  empty result (`found: false`) is a real answer, not an error: the graph has
  nothing relevant, so proceed and record what you learn.
- **`show_queue`** — "what should I work on?" The ranked decision queue, each
  item with a one-line why. For the ordinary "my queue" request, call it with
  no assignee filter; `assignee: "me"` is the narrower view of directly
  assigned or stewarded work only.

For "what happened lately" rather than "what's next", `recent_changes` is the
temporal entry point the other two lack.

## TRAVERSE — gather context before acting

From a starting node, deepen until the picture is complete:

- **`query_graph` with `root_id`** compiles one node's neighborhood — the
  main "go deeper from here" move. Walk outward by re-calling it with each
  related id you surface: a queue item's blockers, a decision's antecedents.
- **`get_node`** fetches one node's full markdown, edges, and `revision` (you
  need the revision to update it). Trust inbound `resolves`/`answers` edges
  over the status field — a node can be retired by an edge before anyone
  flips its status.
- **`render_lens`** runs a saved view; a lineage lens traces why a node
  exists and what it depends on, which is often the fastest way to deepen on
  one node. Called with no `lens_id`, it lists the lenses that exist.

A typical chain: `show_queue` surfaces `issue-tidefall-double-charge`;
`query_graph root_id=issue-tidefall-double-charge` compiles its neighborhood
and surfaces `dec-tidefall-idempotency-keys`; `get_node` on that decision
shows the constraint the fix must respect. Three calls, and the session
starts pre-briefed instead of rediscovering the design.

## COMMIT — write the outcome back

The loop only pays off if outcomes land in the graph:

- **`capture`** is the default write door: two or three standalone sentences
  of prose — the fact, what and why — and the server types it, links it, and
  commits it. Reach for it first when you are unsure what shape the outcome
  should take.
- **`put_node` / `add_edge` / `set_status`** are the precise writes, for when
  you know exactly the node or edge you mean: a new node with chosen id and
  edges, one relationship added, one status transition.
- **Close loops with edges, not just statuses.** When work resolves an issue
  or answers a question, add a `resolves` or `answers` edge from the
  resolving node — that edge is what retires the target from the queue and
  what future traversals trust.

Then the next session's ORIENT finds what this one learned, which is the
point of the loop.
