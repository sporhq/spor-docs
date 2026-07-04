---
title: Schemas are nodes
description: The ontology is data — extend node and edge types by writing schema nodes, versioned with CalVer and gated by sandboxed hooks.
sidebar:
  order: 4
---

**Use this when** you are extending the ontology with a new node or edge
type, an organization-specific write policy, or a replacement queue ranking.

**You do not need this if** the built-in types cover your work; a team can
use Spor indefinitely without touching the schema registry.

Spor's ontology — which node types exist, which edges connect them, what a
status change requires — is not hardcoded. It lives in the **schema
registry**: `type: schema` nodes loaded from a seed pack that ships with
Spor, overridden or extended by schema nodes resident in your graph. Every
hardcoded list would be a place where your organization must adapt to the
tool; the registry inverts that, so the schema adapts to the organization.

Because a schema is an ordinary node, schema history, provenance, review,
and supersession all ride the existing machinery. The registry is the
contract: read it with `spor schema` (or `GET /v1/schema`) rather than
assuming the documentation matches your graph.

## Anatomy of a schema node

A schema node carries a declarative JSON payload and, optionally, attached
code. Suppose the tidefall team wants a `provider-escalation` type for
escalations to its payment provider:

````markdown
---
id: schema-provider-escalation
type: schema
kind: node-schema
schema_version: 2026.06.16.1
title: Schema for provider-escalation nodes
summary: A provider-facing escalation with a required severity field and an
  open/mitigated/closed status machine; closing one requires a resolver.
status: active
date: 2026-06-16
---

```json
{
  "node_type": "provider-escalation",
  "prefix": ["esc-"],
  "queueable": true
}
```

```js
const VALID = ["open", "mitigated", "closed"];

export function validate(node) {
  const errors = [];
  if (!node.severity) errors.push("provider-escalation requires severity");
  const s = (node.status || "").toLowerCase();
  if (s && VALID.indexOf(s) === -1) errors.push("invalid status '" + s + "'");
  return errors;
}

export function transitions(current, proposed, view) {
  if ((proposed.status || "") !== "closed") return { allow: true };
  const ok = (view.resolvers || []).some(
    (r) => r.type === "decision" || r.type === "artifact");
  return ok ? { allow: true } : {
    allow: false,
    reason: "closed requires a decision or artifact that resolves this escalation",
  };
}
```
````

The JSON payload declares **registry knobs**: the type name, id prefixes,
and behavior flags (`queueable`, `traversable`, `always_on`, `capturable`),
plus status partitions (`status.non_resolving`, `status.terminal`). Edge
schemas (`kind: edge-schema`) carry the traversal `weight`, an
`inverse_label`, and `aliases`.

There is deliberately no declarative field list or status enum. Any flat
frontmatter key is carried verbatim on a node; what a field *must* contain,
and which status changes are *legal*, are enforced in attached code.

## The attached hooks

Two pure functions run on the server's write path:

- **`validate(node)`** — the door. Runs on every write, create and update.
  Returns an array of human-readable errors; empty means accept. Required
  fields and status-vocabulary membership belong here, so a node can never
  be born with a value the update path would reject.
- **`transitions(current, proposed, view)`** — the transition gate. Also
  runs on every write (on create, `current` is the proposed node itself — a
  create is not a transition). State-machine legality and completion gates
  live here. The `view` argument is a read-only join the server computes:
  the node's edge targets, its live inbound resolvers, the acting identity,
  and its review approvals.

Two more hooks extend reads and ranking: **`get(node, ctx)`** attaches
derived context when a node is read (an answered question surfacing *what*
answered it) and is fail-soft — a throw drops the enrichment, never the
read; **`queueSignals(node, ctx)`** contributes extra signals to the
decision-queue blend.

All attached code executes in a sandbox: pure functions across a JSON
boundary, no I/O, no clock, no host access, fuel-limited. Gate hooks are
fail-closed — a crashing gate denies the write rather than waving it
through. Sandboxing secures execution; human review of the schema node is
what secures semantics.

## Versioning: CalVer and lazy upgrades

`schema_version` is calendar-versioned (`YYYY.MM.DD.MICRO`). Schemas must
read data written by all earlier versions; when a change is not
backward-readable, the schema carries an ordered chain of pure upgrade
functions, applied lazily when a node is next written and persisted so each
runs once. Resolution is graph-beats-seed wholesale: a resident schema
replaces the seed entry for its type entirely, so keep a resident override's
version in lockstep with seed improvements or retire it (the validator warns
when an override is older than the seed it shadows).

## Proposal and activation: no self-approval

Schema changes go through a review flow the schemas themselves cannot
loosen. A schema node created through the server is forced to
`status: proposed` and is inert — the registry only loads active schemas —
until it is reviewed and activated. Activation requires an identity
**different from the proposal's last author**: the self-approval ban, part
of the server's native floor, exists because a policy layer cannot govern
its own approval without circularity. Proposed schemas surface in the
decision queue as approve items.

A single-person deployment would deadlock on this ban, so a server-side
solo-mode setting can waive it — loudly, with a warning on every waived
approval — until a second identity exists. Trusted admins editing the graph
repository directly bypass the flow by design.

## Beyond node and edge schemas

The `kind:` field admits a few more registry citizens:

- **`policy`** — an org-defined write gate layered on top of the per-type
  `transitions()`. A policy declares a scope (`governs` by types and
  projects) and a `gate()` that is AND-ed with the type's own gate: any deny
  stops the write, so a policy can only add constraints, never loosen them.
  The canonical example is a definition-of-done quorum: `done` requires two
  approvals from people holding the `reviewer` role, the author's own
  approval excluded.
- **`queue-policy`** — a singleton whose attached `rank()` re-scores the
  decision queue, replacing the default blend. Fail-soft: a broken policy is
  reported and the built-in blend stands.
- **`register`** — an extensible enum the kernel exposes as data, such as
  the `requires` register of work risk classes used by
  [dispatch](/reference/dispatch/).

Policies and registers go through the same proposal/activation flow as
everything else they govern.
