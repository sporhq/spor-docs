---
title: Claims and leases
description: How people and agents take work without colliding — a durable assigned edge plus a heartbeat-renewed lease.
sidebar:
  order: 6
---

When several people and background agents share one queue, two of them
picking up the same task is the default failure. Claims prevent it with two
mechanisms that expire on different clocks:

- **The `assigned` edge** is durable graph state: this work belongs to this
  person or agent. It survives restarts, appears in briefings, and drives
  the per-person queue view. It goes away when the work is released or
  finished, not when a session dies.
- **The lease** is ephemeral: a server-held, heartbeat-renewed reservation
  that says someone is *actively working* the node right now. It expires on
  its own if the holder stops renewing — a crashed agent cannot hold a task
  hostage.

## The lifecycle

```bash
spor claim task-api-rate-limits     # take the lease; writes the assigned edge once
spor renew task-api-rate-limits     # heartbeat — bump the lease expiry
spor extend task-api-rate-limits 2h # stretch the lease for a known idle gap
spor release task-api-rate-limits   # drop the lease AND retire the assigned edge
```

The same verbs exist as MCP tools (`claim`, `renew`, `extend`, `release`)
and REST endpoints, and setting a work node to an in-progress status claims
it implicitly. In an agent session the heartbeat is automatic: the client
hooks renew the lease as the session works, so a healthy session never
lapses and a dead one lapses on its own.

Claiming attributes to the authenticated identity — never to a caller
argument — and the claim is what `spor dispatch` takes before launching a
background agent, so duplicate dispatch of an already-claimed node is
refused rather than doubled.

## Conflicts are named, not silent

Claiming a node whose lease another person holds is a conflict that names
the holder and the expiry — you know who to talk to and when the lease
lapses. Re-claiming your own live claim just renews it. Extending is bounded
by the deployment's maximum lease policy (a request past the ceiling is
capped and says so), and it never shortens a lease. Releasing is idempotent:
releasing a node you hold no lease on still succeeds and cleans up any
lingering `assigned` edge of yours, while releasing someone else's claim is
refused.

## Why two mechanisms

A single durable "assigned" flag can't tell "Jo owns this" from "Jo's agent
is mid-flight on this right now", and a single ephemeral lock forgets
ownership every time a session ends. Keeping them separate gives each
consumer the right signal: the queue's carrying view reads the durable edge,
while dispatch-time collision detection reads the live lease. When a lease
lapses but the edge remains, the work still reads as Jo's — it is just no
longer defended against a deliberate takeover.
