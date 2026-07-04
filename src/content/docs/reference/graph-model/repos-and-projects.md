---
title: Repos, projects, and the gardener
description: Two-layer grouping — git repos under stable project groupings — and the automated hygiene sweep that files findings as queue items.
sidebar:
  order: 8
---

One graph spans all of a team's work, so nodes need a home. Spor groups them
in two layers, because "project" pulls apart the moment a product spans more
than one repository: a **repo** is one git identity, and a **project** is
the stable grouping above repos.

## Repo nodes: durable git identity

A session's repo slug is inferred from the repository (the repo basename,
kebab-cased; a committed `.spor` marker with `repo: <slug>` beats
inference). A rename would orphan every historical stamp, so a `repo-` node
makes the identity data instead:

```markdown
---
id: repo-parcel-api
type: repo
title: parcel-api
summary: The parcel-tracking API service.
slugs: [shipping-api, parcel-api]
fingerprints: [remote:github.com/example/parcel-api, root:47520dcafe1b]
date: 2026-05-01
edges:
  - {type: grouped-under, to: proj-parcel}
---
```

- `slugs` lists every slug that has ever named the repo, oldest first.
  Historical nodes stamped with an old slug are never rewritten; readers
  resolve aliases at read time, so one edit heals all history.
- `fingerprints` accumulates evidence (root commits, remote URLs). An
  unknown slug arriving with a known fingerprint is rename evidence — the
  server files an alias proposal in the queue for a human to confirm.
- `status: archived` retires a finished repo: its open work leaves every
  viewer's queue (counted, never silent) while its history stays reachable.

Git worktrees resolve to their main repository, so every worktree of one
repo shares one identity. In a monorepo, a subtree can carry its own `.spor`
marker, splitting one git repo into distinct identities by directory.

## Project groupings and slug up-resolution

A `proj-` node is the grouping: no git identity, no fingerprints, just a
title and the repos `grouped-under` it. A repo joins exactly one home
project; a shared repo (`auth`, `infra`) belongs to its own platform
grouping rather than being co-owned — cross-cutting *work* stays edges
between work nodes, never repo co-ownership.

Every read surface (queue, briefing, digest, analytics) resolves its scope
token through one shared up-resolution:

| Scope token | What it reads |
| --- | --- |
| `parcel-api` (bare slug) | The whole home-project union — every repo grouped under `proj-parcel` |
| `repo-parcel-api` (repo node id) | Just that one repo |
| `proj-parcel` (grouping id) | The grouping, directly |
| nothing | The cross-project firehose |

The intuitive token returns the whole product, and the node ids are the
escape hatches to narrower or exact scope. An ungrouped repo simply resolves
to itself, so a graph with no project nodes behaves as before.

## The gardener: hygiene as queue items

Graphs rot in predictable ways: a task's anchors get superseded, work goes
cold, a `blocks` edge outlives the blocker. The gardener is a periodic
server-side sweep that runs these checks and **files its findings as queue
items** rather than acting — backlog grooming stops being a meeting and
becomes ranked items with compiled context.

Findings are ordinary `find-` nodes written through the validated,
attributed write path (`authored_via: gardener`) with deterministic ids, so
re-sweeps are idempotent. What v1 looks for:

- **stale-anchors** — a live node edged to a superseded target: "the ground
  moved under this; still true?"
- **cold-work** — in-progress work with no neighborhood activity for two
  weeks.
- **inert-gate** — a `blocks` edge whose source reached a terminal status
  while the target still reads blocked. The gate has cleared; drop the edge
  or pick up the work.
- **unedged-gate** — a live decision that sequences work in prose ("X is
  gated on Y") without the `blocks` edge that would feed the queue's
  blocking signal. The finding asks a human to add the edge or dismiss.
- **resolved-open** — a node retired by a live inbound `resolves`/`answers`
  edge whose status field still reads open. Read surfaces already treat it
  as resolved; the finding nags a human to flip the field.

The gardener performs exactly one mutation: when a finding's condition
clears, it resolves its **own** finding — never a human-authored node.
Everything else is filed, not acted.

Findings route to stewards the same way [questions](/use-spor/capture/) do:
the finding's subject neighborhood is walked for the closest steward, a
`routed-to` edge materializes the route, and the queue shows each person the
findings routed to them plus any unrouted ones. Gardener output lands with
whoever stewards what it observed, not with everyone.
