---
title: Agents and attribution
description: Agent identities, on-behalf-of attribution, and the token trail that makes agent work auditable.
sidebar:
  order: 6
---

Teams on hosted Spor rarely write to the graph only by hand — coding agents
capture, file, and resolve nodes too. Hosted Spor's rule for this is simple:
**an agent never writes as itself alone; it writes on behalf of the person
who owns it.** That chain — person, to agent, to the specific run — is the
audit trail.

## Agent principals

An agent is a node in the graph, owned by a person through an `owned-by`
edge. Creating one is self-serve — you need no admin privilege to run your
own agents:

```bash
spor agent create --label "ci-reviewer"
spor agent list
```

Ownership is what authorizes everything else: only the owning person can mint
tokens for an agent, and the owner is resolved from the graph at verification
time — never asserted by the caller — so a deleted agent or owner makes its
tokens fail closed rather than impersonate anyone.

## How attribution works

When a write arrives under an agent-scoped token, the server stamps the
attribution itself, from the token: the `author` stays the **owning person**,
the agent's id rides along as `authored_by_agent`, and the run's session id is
recorded when one is bound. Any attribution a client puts in the payload is
discarded. The result is a node that reads "agent, on behalf of person" — you
can always answer both *whose work is this* and *which run produced it*.

The same signal surfaces in the audit views: the recent-changes feed
(`GET /v1/changes`, or the `recent_changes` MCP tool) marks each change as
machine- or human-authored, and a node's history shows the full chain of
editors over time — useful because a node's visible `author` field reflects
only the last writer.

## Agent tokens

Two kinds, both minted by the owner against their own agent:

- **Per-session tokens** are short-lived, minted for a single run — this is
  what `spor dispatch` does automatically, so a dispatched background agent's
  graph writes carry its identity without any manual token handling. The run's
  session is bound to the token once and is write-once thereafter; it cannot
  be forged or swapped after the fact.
- **Standing tokens** are long-lived agent credentials for headless
  environments that outlive any one session (a cloud agent, a CI job). Like
  personal tokens they are shown once, capped at a year, and listable and
  revocable per agent — so one environment's credential can be rotated
  without touching the owner's other access.

Endpoint detail for all of this is in the [API reference](/reference/api/).

## Capabilities and profiles

For teams routing work across several machines, an agent can publish the
capabilities of the box it runs on, and a task can carry a **profile**
declaring what it needs; the server matches profiles against published
capabilities so work is routed to a machine that satisfies it rather than
silently run somewhere that doesn't. The model behind profiles and
capabilities is covered in [Concepts](/start-here/core-ideas/).
