---
title: Identity and attribution
description: People as identity anchors, organizations, and agents that write "on behalf of" their owner.
sidebar:
  order: 7
---

**Use this when** you want to know who a write is attributed to, how agents
write on behalf of a person, or how routing and review resolve through
identity.

**You do not need this if** you work alone on a personal local graph; start
with [Core ideas](/start-here/core-ideas/) until more than one person or
agent writes.

**After reading this, you should be able to** read a person node's routing
fields, explain organization authority edges, and tell a person's write from
an agent's write on their behalf.

In remote mode, identity is graph-native: people, organizations, and agents
are nodes, and everything that depends on who you are — attribution,
routing, per-person queues, review quorums — resolves through edges to those
nodes.

## Person nodes

A `person-` node is a member's identity anchor. Every authenticated token's
canonical subject is a person node, and the `{name, email}` attribution on a
write resolves *from that node at read time*:

```markdown
---
id: person-ines
type: person
name: Ines Duarte
title: Ines Duarte
summary: Billing lead; stewards the dunning-flow spec and the retry path.
email: ines@tidefall.example.com
roles: [reviewer]
date: 2026-05-02
edges:
  - {type: stewards, to: spec-tidefall-dunning-flow}
  - {type: member-of-org, to: org-tidefall}
---
```

The design detail that matters: **email is an attribute, not the key**. The
token binds to the person node's id; `email` is a re-pointable field, so
changing it re-points attribution and routing instead of severing them. The
opaque `person-` id stays the stable machine reference for edges, filters,
and token subjects, while `name` is the mutable display label.

A few fields do real work:

- **`stewards` edges** declare ownership of an area, spec, or norm — the key
  [question routing](/use-spor/ask-and-answer-questions/) walks.
- **`roles`** is the qualification register org policies read: a
  definition-of-done quorum counts approvals from people holding a named
  role.
- **`queue_mute`** hides listed projects or nodes from this person's queue
  view only.
- **`github`** maps a GitHub login to this person, so reflected PR reviews
  attach to the right person's review edges.

Onboarding a teammate is three deliberate steps: author the person node, add
their `stewards` edges, and mint a token bound to the node. Skip the
stewards edges and questions in their area route to no one; mint the token
before the node exists and their personal queue stays empty. `spor whoami`
(and the `bound` flag it reports) is the check that a token actually maps to
a person node.

## Organizations

An `org-` node is a durable organization identity anchor. A person's
`member-of-org → org-tidefall` edge records membership; an additional
`stewards → org-tidefall` edge records org-admin authority. Provider roles and
email domains confer neither — authority is always an explicit edge in the
graph, visible and auditable like everything else.

## Agents: person-owned principals

An `agent-` node is a person's automation principal — the durable identity
of a dispatched background session:

```markdown
---
id: agent-ines-laptop
type: agent
title: Ines's laptop agent
summary: Dispatched-session principal on Ines's laptop; owned by person-ines.
status: active
date: 2026-05-20
edges:
  - {type: owned-by, to: person-ines}
---
```

An agent node is persistent, typically one per machine or install, created
once (`spor agent create <label>`) and reused across every dispatch — not
one node per session. Ownership lives on the `owned-by` edge, a low-weight
structural binding that never pulls the owner into the agent's work
neighborhoods.

## Agent on behalf of person

Work an agent writes is attributed twice, deliberately:

- `author:` stays the **owning person** — so routing, history, per-person
  queues, and "who did this" all behave exactly as if the person had written
  it;
- `authored_by_agent: agent-ines-laptop`, `authored_via: dispatch`, and
  `session: <run-id>` are added — so you can always tell it was the agent,
  and which run.

All attribution stamps are derived from the authenticated token, never from
the write payload, so they cannot be forged by a caller. The
`person → agent` ownership chain is the audit trail, and it is also a policy
boundary: an agent acting on behalf of Ines counts *as Ines* for the
self-approval ban and review quorums, so Ines's reviewer-agent cannot approve
Ines's implementer-agent's work past the org bar.

Agent tokens are self-serve and ownership-gated: a person mints short-lived
per-session tokens (or a standing token for a headless agent) only for
agents they own — no admin privilege involved, and a deleted agent or owner
makes the token fail closed rather than impersonate.
