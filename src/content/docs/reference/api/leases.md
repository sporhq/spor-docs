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

## Bulk lease endpoints

Agents commonly work a **working set** of several related nodes at once —
claimed together, heartbeat together, handed back together. The endpoints
above cost one round-trip per node; these cost one round-trip per **call**,
each delegating per item to the identical singular verb (same per-node
locking, same durable-edge writes, same holder rule), so a batch behaves
exactly like N sequential calls, just faster.

An individual item can still legitimately fail inside an otherwise
successful batch — a claim losing a race, a renew finding a lapsed lease — so
`claim`/`renew` report per-item outcomes instead of failing the whole
request: `ok: true` means the call was well-formed, not that every item
landed. Always read `failed` for what didn't. `release` is the one exception
below: it only ever drops the caller's own leases, so it has nothing to
refuse.

## POST /v1/queue/claim

Claim a whole working set in one round-trip. Body: `{"ids": [...],
"session"?: "..."}`.

```sh
curl -s https://api.sporhq.io/v1/queue/claim \
  -H "Authorization: Bearer $SPOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"ids": ["task-tidefall-retry-emails", "task-tidefall-retry-rollout"]}'
```

`ids` is **required** — unlike renew below there is nothing to enumerate; a
claim creates the lease it would have enumerated. Each id runs through the
same logic as the singular `/claim`: a node another holder already has lands
in `failed` as `already_claimed` (naming the holder) while the rest of the
batch still claims — a partial batch is reported, never rolled back.

Returns `{ok: true, status, count, claimed: [ids], leases: [...], failed:
[{node_id, code, message, holder?}]}`. `status` is `"claimed"` when every id
landed, `"partial"` when some did, `"refused"` when none did. The dispatch
nonce and `force` accepted on the singular `/claim` are deliberately not
accepted here — a dispatch tags a single agent launch at a single node, so
that stays on the singular door.

## POST /v1/queue/renew

The heartbeat for a whole working set in one round-trip. Body: `{"ids"?:
[...], "session"?: "..."}`.

Two modes: **`ids` omitted** enumerates every live lease this caller holds
(optionally narrowed to one `session`) and renews them all — the motivating
case, one call per heartbeat instead of one per held node; **`ids` supplied**
renews exactly that set, with `session` forwarded unchanged exactly as the
singular `/renew` does. A lease that lapsed or was stolen out from under the
caller lands in `failed` as `lease_lost` (naming the current holder) while
the rest of the set still renews — one contested node never costs the whole
working set its heartbeat.

Returns `{ok: true, status, count, renewed: [ids], leases: [...], failed:
[...], skipped_other_session?, skipped_reserved?}`. The two optional counts
ride only on the enumerate arm (`ids` omitted): `skipped_other_session`
names live leases excluded because they're bound to a different session (a
zero `renewed` count there means "not under this session", not "you hold
nothing"); `skipped_reserved` names resumption reservations (`/reserve`) a
blanket heartbeat deliberately leaves parked at their grace-window expiry
rather than demoting to a normal lease horizon.

## POST /v1/queue/release

The session-handoff drain: release every live claim the caller holds,
optionally narrowed to one `session`, in one round-trip instead of N
sequential `/release` calls. Body: `{"session"?: "..."}`.

```sh
curl -s https://api.sporhq.io/v1/queue/release \
  -H "Authorization: Bearer $SPOR_TOKEN" \
  -H "Content-Type: application/json" -d '{}'
```

Never fails on a holder mismatch — it only ever enumerates and drops the
caller's **own** live leases, so unlike the two endpoints above it carries no
`failed`/409-conflict arm. Returns `{ok: true, status: "released", released:
[ids], count}`.
