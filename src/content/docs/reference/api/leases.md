---
title: Leases
description: Claim, renew, extend, reserve, and release — heartbeat-renewed ownership of queue items.
sidebar:
  order: 5
---

A claim is two things: a durable `assigned` edge on the node (visible in the
graph) and an ephemeral, heartbeat-renewed **lease** that expires if the
claimer goes quiet. The lease is what prevents two workers from picking up
the same queue item; the edge is what records who carried it. Setting a work
node to an in-progress status via
[`POST /v1/nodes/{id}/status`](/reference/api/writes/) claims it with the same lease.

The claimer is always the authenticated identity — never a request argument.

## POST /v1/nodes/{id}/claim

Take the lease. Body: `{"session"?: "..."}`.

```sh
curl -s https://api.sporhq.io/v1/nodes/task-tidefall-retry-emails/claim \
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

## POST /v1/nodes/{id}/reserve

Convert your live claim into an owner-exclusive **resumption reservation** —
for a session that ends cleanly with the task advanced but unfinished. Body:
`{"session"?: "..."}`.

```sh
curl -s https://api.sporhq.io/v1/nodes/task-tidefall-retry-emails/reserve \
  -H "Authorization: Bearer $SPOR_TOKEN" \
  -H "Content-Type: application/json" -d '{}'
```

Returns `{ok, status: "reserved", lease, grace_window_ms}`. The heartbeat
lease is not held overnight; instead the reservation keeps the task at the
top of your own queue and out of teammates' actionable lists for a grace
window (tenant policy, echoed as `grace_window_ms`), then escalates back to
the pool at normal priority for everyone if no further activity lands. The
durable `assigned` edge is left untouched, so a steward view still shows the
node reserved by you.

- You may reserve only a node you currently hold a **live** lease on — a
  lapsed lease or one held by someone else is `409 lease_lost`, naming the
  holder.
- Returning and claiming (or renewing/extending) the node re-establishes a
  fresh heartbeat lease.
- Reach for this instead of `release` when you intend to pick the task back
  up yourself; reach for `release` when you're handing it back to the pool
  for good.

## POST /v1/nodes/{id}/release

Drop the lease **and** retire the durable `assigned` edge, returning the node
to the pool. Idempotent: releasing a node you hold no lease on still
succeeds, cleaning up any lingering `assigned` edge of yours. Releasing a
claim someone else holds is `409`, naming the holder.
