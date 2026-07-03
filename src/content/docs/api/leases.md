---
title: Leases
description: Claim, renew, extend, and release — heartbeat-renewed ownership of queue items.
sidebar:
  order: 5
---

A claim is two things: a durable `assigned` edge on the node (visible in the
graph) and an ephemeral, heartbeat-renewed **lease** that expires if the
claimer goes quiet. The lease is what prevents two workers from picking up
the same queue item; the edge is what records who carried it. Setting a work
node to an in-progress status via
[`POST /v1/nodes/{id}/status`](/api/writes/) claims it with the same lease.

The claimer is always the authenticated identity — never a request argument.

## POST /v1/nodes/{id}/claim

Take the lease. Body: `{"session"?: "..."}`.

```bash
curl -s https://api.sporhq.io/v1/nodes/task-api-rate-limits/claim \
  -H "Authorization: Bearer $SPOR_TOKEN" \
  -H "Content-Type: application/json" -d '{}'
```

Writes the durable `assigned` edge once and creates the lease, returning
`{ok, status, lease: {node_id, by, expires, expires_at, session, claimed_at},
edge}`.

- A live lease held by **another** person is `409 conflict`, naming the
  holder and expiry.
- Re-claiming your **own** live claim just renews it.
- `session` scopes the heartbeat to one run. Omit it to leave the lease
  person-scoped, so any of the claimer's sessions may renew — useful when the
  run's session id is not known until after launch.

## POST /v1/nodes/{id}/renew

The heartbeat: bump the live lease's expiry only — no graph commit. Body:
`{"session"?: "..."}`.

A lapsed or stolen lease is `409`, naming the current holder. Renewal is
person-scoped (any of the claimer's sessions may renew); passing a `session`
binds the lease to that run.

## POST /v1/nodes/{id}/extend

Manually stretch your live lease by `ms` milliseconds for a known long idle
gap. Body: `{"ms": 7200000, "session"?: "..."}`.

Returns `{ok, status, lease, capped_to_max?, claim_ttl_max_ms?}`. The
extension is bounded by the tenant's maximum claim TTL policy — a request
past the ceiling caps to it, flagged `capped_to_max` — and never shortens a
lease. `ms` must be a positive number. A lapsed or stolen lease is
`409 lease_lost`, naming the holder.

## POST /v1/nodes/{id}/release

Drop the lease **and** retire the durable `assigned` edge, returning the node
to the pool. Idempotent: releasing a node you hold no lease on still
succeeds, cleaning up any lingering `assigned` edge of yours. Releasing a
claim someone else holds is `409`, naming the holder.
