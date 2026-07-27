---
title: The node model
description: One fact per node — markdown files with typed ids, standalone summaries, git-derived timestamps, and a gate on completing work.
sidebar:
  order: 1
---

**Use this when** you write or edit node files by hand in local mode, build
tooling that writes nodes, or need the exact rule behind a rejected write
such as the resolver gate refusing to close a task.

**You do not need this if** you write through capture and the everyday loop,
where the node format is handled for you; for the basic idea, read [Core
ideas](/start-here/core-ideas/).

**After reading this, you should be able to** write a valid node id and
standalone summary, add frontmatter edges, and explain why a task cannot move
to `done` without a resolver.

A Spor node is one markdown file in the graph home's `nodes/` directory:
YAML frontmatter for the structured fields, a short prose body underneath.
Here is a decision from the fictional
[tidefall team](/contributing/example-scenario/)'s billing retry work:

```markdown
---
id: dec-tidefall-billing-retries
type: decision
repo: billing
title: Failed card charges retry three times over two days before the update-billing email
summary: Failed card charges retry three times over two days, then a dunning
  email asks the customer to update billing details, because a single
  immediate retry recovered too few charges.
status: active
date: 2026-06-12
edges:
  - {type: derived-from, to: spec-tidefall-dunning-flow}
  - {type: supersedes, to: dec-tidefall-retry-once}
---

Retry-once was the launch design and recovered too few charges; customers
churned after one transient card failure. The three-attempt window over two
days recovers most of them. A longer window was rejected because it delays
the update-billing email past the next billing cycle.
```

## The `repo` field names the originating repo

`repo: billing` above is a scalar stamp naming the git repo the node was
written in — inferred from the checkout at write time, or fixed by a
committed `.spor` marker (see [Configuration](/reference/configuration/)).
If you write a node file by hand, stamp `repo:`, not `project:`: `project:`
is the old spelling of this same field, kept only because existing stamps
are never rewritten, so older nodes still read `project` while everything
written today writes `repo`. Both spellings are valid to read; only `repo:`
is valid to write.

Don't confuse this per-node stamp with the separate `type: repo` and `type:
project` node types, a durable identity layer where a `repo-` node owns a
repo's git identity (slug aliases, fingerprints) and a `proj-` node groups
repos into the stable product above them — see [Repos, projects, and the
gardener](/reference/graph-model/repos-and-projects/) for that layer.

## One fact per node

A node records a single fact. If you find yourself writing "also" a lot,
split it — two facts in one node means one of them is invisible to every
edge, filter, and queue signal that would otherwise find it. The body stays
short, a few paragraphs at most, written for a reader with zero session
context.

## Ids are typed, kebab-case, and immutable

The `id` must equal the filename minus `.md`, be kebab-case, and start with
its type's prefix: `dec-` for decisions, `task-` for tasks, `issue-` for
issues, and so on (the full table is on [Node types](/reference/graph-model/node-types/)).
An id never changes once created. Everything else about a node can move —
its status, its edges, even its title — but the id is the stable reference
that edges, briefings, and commit trailers point at.

## The summary must stand alone

`summary` is mandatory, and it is the field most consumers see. When Spor
compiles a briefing, most nodes appear at summary resolution; only the nodes
that score highest are shown with their full body. Write the summary as one
or two sentences that carry the fact and the why on their own:

- Weak: "Decision about billing retries."
- Strong: "Failed card charges retry three times over two days, then a
  dunning email asks the customer to update billing details, because a single
  immediate retry recovered too few charges."

If the summary only makes sense next to the body, the briefing that shows it
without the body will mislead.

## Timestamps come from git

The graph home is a git repository, and git is the source of truth for
system time. A node's `created_at` is the first commit that touched its
file; `updated_at` is the last. Neither is stored in the node bytes, which
keeps files byte-identical across reads and makes history tamper-evident.

The frontmatter `date` field is different: it records when the underlying
event happened (the day the decision was made), not when the node was
written. Explicit `created_at`/`updated_at` frontmatter is accepted as an
override for graphs whose git history was squashed or rebased, and `date` is
the last-resort fallback when git has nothing.

## Edges live in frontmatter

Edges are written on the source node as `- {type: <edge>, to: <id>}` entries.
An edge may point at an id that does not exist yet; the compiler skips it,
and the dangling reference marks a node worth creating — don't delete it.
An edge may also carry extra flat attributes after `to:`, such as the
per-assignment profile override on an `assigned` edge
(`- {type: assigned, to: agent-ines-laptop, profile: profile-reviewer}`).

Two optional scalar fields connect nodes to work outside the graph:

- `commits: [billing@1a2b3c4, ...]` links a node to the code commits that
  implement it. Commits are deliberately not nodes — a node per commit would
  mirror `git log` and drown the curated graph.
- `wake: YYYY-MM-DD` parks a queueable node as dormant until the date
  arrives, the renew-the-certificate shape — see
  [the decision queue](/use-spor/queue/).

## Completing work needs a durable why: the resolver gate

Flipping a task to `done` or an issue to `resolved` requires a live inbound
`resolves` edge from a `decision` or `artifact` node. This is the resolver
gate, and it is the node model's central discipline: the outcome must live
on the graph, where its neighborhood can surface it, instead of evaporating
into a status flip.

A heavyweight closure earns a decision node (the why). A trivial one earns a
few-line artifact (what was done, like a commit message). Either satisfies
the gate. A task abandoned as won't-do is exempt — abandoning produces
nothing worth recording.

The gate runs at write time on both create and update, so a node can no more
be born `done` than be flipped there without a resolver. The resolver must
also be in a resolving state: an artifact whose delivery status is still
`in-review` or `approved` keeps the task live; `merged`, `released`, or no
delivery status resolves it. Which statuses count as resolving is registry
data, so a team can retune the bar by editing a schema node — see
[Schemas are nodes](/reference/graph-model/schemas/).

:::note
The gate is enforced on server-mediated writes. In local mode you edit node
files directly, and file writes are ungated — the discipline still applies,
but nothing stops you.
:::

## Status vocabulary is write-gated, separately from transition legality

A type's schema can gate a status two different ways (see [Schemas are
nodes](/reference/graph-model/schemas/)): `validate(node)` checks the node in
isolation on every write, create and update — is this a word the type
recognizes at all — while `transitions(current, proposed, view)` checks
whether one *specific* change is legal given the node's history and
neighborhood. A type can carry either, both, or neither; the two are
independent gates, not two names for the same check.

`artifact` gates only through `validate()` — it has no `transitions()`,
because its stages are not a state machine: a change may be born `merged`,
and a living doc may move `active` → `done` and back, so there is nothing
to gate on order. What `validate()` enforces instead is vocabulary
membership: every write's status must be empty (a plain reference doc) or
one of `in-review`, `approved`, `merged`, `released`, `done`, `active` — see
[Node types](/reference/graph-model/node-types/#work-and-knowledge-types).
A server-mediated write with an off-vocabulary status (`shipped`,
`complete`, `landed`) is rejected as `422 invalid_node`, on create exactly as
on update, the same as a missing required field.

Don't confuse this with the resolver gate above, which is a `transitions()`
concern: whether an artifact's *current* delivery status (`in-review` /
`approved` vs. `merged` / `released` / none) lets it resolve a task or issue.
Membership asks whether the value is a word this type recognizes at all,
independent of what it's changing from or to; legality asks whether this
specific change, in this specific context, is allowed.

## Attribution

When a node is written through the Spor server, the server stamps
`author: Name <email>` and `authored_via: mcp|rest|capture|dispatch|gardener`
from the authenticated identity. Any author supplied in the payload is
discarded. Locally written nodes may omit both. The `authored_via` stamp is
the durable machine-vs-human signal: `capture` marks nodes drafted by the
ingestion path, `gardener` marks automated sweep findings, `dispatch` marks
work written by an agent on behalf of its owner.
