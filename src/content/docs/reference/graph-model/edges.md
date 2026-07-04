---
title: Edge types
description: Every edge type, written from the source node's perspective, with traversal weight and inverse forms.
sidebar:
  order: 3
---

Edges are typed, directional, and weighted. Every edge is written from the
**source node's perspective**: `- {type: resolves, to: issue-webhook-retries}`
on a decision means "this decision resolves that issue". Weights control how
far the briefing compiler follows a relationship — high-weight edges decay
slowly across hops, which is what makes structural traversal beat plain
similarity search.

Prefer one precise high-weight edge over three `relates-to`.

## Lineage and dependency edges

| Edge | Weight | Meaning (from the source node) |
| --- | --- | --- |
| `supersedes` | 1.0 | This node replaces the target; the target is stale. |
| `constrained-by` | 1.0 | The target limits what this node may do. |
| `governed-by` | 0.95 | The target is the norm or policy this node falls under. |
| `derived-from` | 0.9 | This node was produced from the target. |
| `decided-in` | 0.9 | The choice in this node was made in the target. |
| `resolves` | 0.9 | This node fixes or closes the target — the edge the [resolver gate](/reference/graph-model/nodes/) requires. |
| `blocks` | 0.7 | The target cannot proceed until this node does. |
| `answers` | 0.7 | This node answers the target question, pulling the answer through the asker's next briefing. |
| `relates-to` | 0.5 | Weak association. |
| `mentions` | 0.5 | Weakest association. |

## People and routing edges

| Edge | Weight | Meaning (from the source node) |
| --- | --- | --- |
| `assigned` | 0.5 | This work is assigned to the target person or agent — the explicit-routing edge. An agent target may carry a `profile:` override. |
| `reviewed-by` | 0.5 | The target person reviewed and approved this node; counts toward a policy quorum. |
| `changes-requested-by` | 0.5 | The target person reviewed this node and requested changes — not an approval. |
| `stewards` | 0.4 | The source person stewards the target area, spec, or norm — the question-routing key. |
| `review-requested` | 0.3 | A review of this node is requested of the target person; surfaces in their queue. |
| `routed-to` | 0.3 | This question was routed to the target person for answering. |

The three review edges are mutually exclusive per node-and-person pair: the
edge type *is* that reviewer's current verdict, and writing one flips any
sibling review edge to the same person in place. A reviewer turns a pending
`review-requested` into `reviewed-by` with a single edge write.

## Structural identity edges

Low-weight by design: they bind identities together without pulling owners
and groupings into every work neighborhood.

| Edge | Weight | Meaning (from the source node) |
| --- | --- | --- |
| `member-of-org` | 0.3 | The source person is a member of the target organization. |
| `grouped-under` | 0.3 | The source repo's home project grouping. |
| `owned-by` | 0.3 | The source agent is owned by the target person. |
| `uses-profile` | 0.3 | The source agent's default dispatch profile. |

## Workflow and provenance edges

| Edge | Weight | Meaning (from the source node) |
| --- | --- | --- |
| `performs` | 0.8 | This run is an execution of the target workflow. |
| `triggered-by` | 0.7 | This run was triggered by the target node or event. |
| `compiled-for` | — | Briefing to its task or query; provenance only, no traversal weight. |
| `shaped-by` | — | Briefing to the corrections applied to it; provenance only. |

## Inverse labels and aliases

Write edges in the canonical direction above, but the write path accepts two
normalized forms:

- **Inverse labels** — the same edge read from the target's side. Writing
  `{type: blocked-by, to: issue-webhook-retries}` on
  `task-carrier-rollout` is flipped and stored on the issue as
  `{type: blocks, to: task-carrier-rollout}`. Registered inverses:
  `blocked-by` → `blocks`, `answered-by` → `answers`,
  `superseded-by` → `supersedes`, `groups` → `grouped-under`,
  `owns` → `owned-by`, `has-org-member` → `member-of-org`.
- **Aliases** — same-direction synonyms renamed in place: `related-to` →
  `relates-to`, `derives-from` → `derived-from`, `supercedes` →
  `supersedes`, `approved-by` → `reviewed-by`.

Unknown edge types beyond this vocabulary are rejected, not silently
defaulted. Hand-written nodes should use the canonical forms.

## Weights are registry data

The table above shows the seed pack's weights. Like everything else in the
ontology, edge types and their weights live in schema nodes, so a team can
add an edge type or retune a weight by writing a schema node rather than
waiting for a release. `spor schema --edges` prints the live table for your
graph. View-layer schemas may add their own structural edges — for example,
a workspace mirrors its lens slots with low-weight `composes` edges.
