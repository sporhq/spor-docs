---
title: Tokens and agents
description: Self-serve and admin token lifecycle, agent identities, agent tokens, capabilities, and host matching.
sidebar:
  order: 7
---

Token lifecycle runs entirely over REST, so onboarding and offboarding need
no server-box shell. Two tiers: the `/v1/me/*` routes are **self-serve**
(scoped to the caller's own identity), the `/v1/admin/*` twins are
**admin-only** (the `stewards → root` gate — see
[Authentication](/api/authentication/#the-admin-gate)). Agent routes are
gated by **ownership**, not admin: you manage the agents you own.

## Personal access tokens (self-serve)

### GET /v1/me/tokens

List the caller's own personal access tokens: `{tokens: [{hash_prefix,
person, label, name, email, created, expires, expired, last_used}], count}`.
Never plaintext, never full hashes; agent session tokens are excluded. `403`
if the bearer maps to no person node — a bound identity is required to own a
PAT.

### POST /v1/me/tokens

Mint a `spor_pat_` token bound to the caller's own person node:

```bash
curl -s https://api.sporhq.io/v1/me/tokens \
  -H "Authorization: Bearer $SPOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"expires": "90d", "label": "laptop"}'
```

Returns 201 `{token, hash_prefix, person, name, email, label, expires}` —
the plaintext `token` is returned **once**. `expires` is `<N>d` or an ISO
date, defaulting to and capped at 1 year (a past date or beyond-cap value is
`422`, rejected rather than silently clamped); `label` is an optional note of
at most 200 characters, surfaced in the listing. `403` if unbound.

### DELETE /v1/me/tokens/{hash-prefix}

Revoke one of the caller's own tokens by hash prefix. Returns `{revoked,
hash_prefix, oauth_grants_revoked}` — revocation cascades to the OAuth grants
minted from that token. A prefix that isn't one of the caller's is `404`
(never another person's token). `403` if unbound.

## Personal access tokens (admin)

### GET /v1/admin/tokens

The team-wide token list: `{tokens: [{hash_prefix, person, name, email,
created, expires, expired}], count}`. Never plaintext, never full hashes.

### POST /v1/admin/tokens

Mint a token bound to an existing person node — someone *else*, for
onboarding: `{"person": "person-jo", "expires": "30d"}` returns 201 `{token,
hash_prefix, person, name, email, expires}`, plaintext returned once.

### DELETE /v1/admin/tokens/{hash-prefix}

Revoke the single token matching the hash prefix (at least 8 hex characters;
an ambiguous prefix is `409`). Returns `{revoked, hash_prefix}`. Revokes any
token; the self-serve route above revokes only your own.

## Agents

An agent is a graph node representing an automated worker, owned by a person
via an `owned-by` edge. Writes under an agent's token are attributed "agent
on behalf of person" (see
[Authentication](/api/authentication/#agent-session-tokens)).

### GET /v1/agents

List the agents the caller **owns**: `{agents: [{id, label, owner, spiffe,
pubkey, status}], count}`. `?all=1` lists every agent (admin-only).

### POST /v1/agents

Self-serve — not admin. Create an agent node owned by the **caller's** bound
person, plus its `owned-by` edge: `{"label": "ci-runner", "id"?, "pubkey"?}`.
The owner is never payload-asserted; `id` derives from `label` when omitted.
Returns 201 `{id, owner, spiffe, pubkey, status, revision}`. A duplicate id
is `409`, an invalid body `422`, and a caller with no person node `403` (you
need a subject to own one).

### POST /v1/admin/agents

Create an agent on behalf of **another** person: `{"label": "ci-runner",
"owner"?: "person-jo", "id"?, "pubkey"?}` (`owner` defaults to the caller's
person). Same response and errors as the self-serve door, plus `403` for
non-admins.

## Agent tokens

### POST /v1/agents/{id}/token

Self-serve, ownership-gated: the caller's person must **own** the agent,
else `403`; an unknown agent is `404`. Two modes:

**Per-session** (default): mint a short-TTL token scoped to the agent —
`{"session"?, "audience"?, "expires"?}` returns 201 `{token, expires_at,
agent, session}` (`session: null` when deferred). `session` is optional:
dispatch tooling mints the token session-deferred when the run's session id
is not known until after launch, then binds the real one via
`POST /v1/agents/session` below. A caller-supplied `expires` may only
**shorten** the default TTL, never extend it past the 7-day cap; a malformed
supplied `session` is `422`.

**Standing** (`{"standing": true, "expires"?, "label"?}`): mint a long-lived
agent-scoped `spor_pat_` — the durable `SPOR_TOKEN` a headless agent runs
under. Returns 201 `{token, hash_prefix, agent, owner, label, expires,
standing: true}`. `expires` defaults to and is capped at 1 year (past or
beyond-cap is `422`, rejected not clamped); `label` is an optional note of at
most 200 characters; a supplied `session` is `422` — a standing credential
carries none.

In both modes, writes under the token are stamped agent-on-behalf-of-person.

### GET /v1/agents/{id}/tokens

List the agent's **standing** tokens: `{tokens: [{hash_prefix, label,
standing, created, expires, expired, last_used, ...}], count}`. Short
per-session tokens are excluded — they age out on their own. Same ownership
gate as the mint.

### DELETE /v1/agents/{id}/tokens/{hash-prefix}

Revoke one of the agent's standing tokens by hash prefix: `{revoked,
hash_prefix, oauth_grants_revoked}`. A prefix that isn't one of **this**
agent's standing tokens is `404` — never a session token or another agent's.
Same ownership gate, so a credential is revocable per environment without
touching the owner's other access.

### POST /v1/agents/session

Late session binding for a session-deferred agent token. Authenticated by the
**agent token itself** — the bearer identifies its own record, so there is no
agent id in the path and only an agent-scoped token may call it (`403`
otherwise). Body `{"session": "..."}` sets that token's session and returns
`{ok, agent, session}`.

**Write-once**: idempotent on the same value (`{unchanged: true}`), `409
conflict` on a different one — a token's session is provenance, not a mutable
field. A missing or malformed `session` is `422`. Every subsequent write
under the token then stamps the bound session.

## Capabilities and host matching

Machine capabilities are operational state stored beside the agent node —
probe-refreshed, never committed to the graph.

### POST /v1/agents/{id}/capabilities

Publish a machine's capabilities: `{"harnesses"?, "reachable_mcp"?,
"skills"?, "plugins"?, "deny"?}` (a raw `{probed, declared, deny}` map or a
`{capabilities: {...}}` envelope also work — the server collapses them the
same way the client does). Returns `{agent, capabilities, published_at,
last_seen, published_by, session?, changed}`.

Authorized if the caller **owns** the agent or **is** the agent (a
self-publish under an agent token) — else `403`; `404` unknown agent; `422` a
malformed map. A publish stamps both `published_at` (when the capabilities
last changed) and `last_seen` (last contact); staleness in host matching keys
off `last_seen`.

### GET /v1/agents/{id}/capabilities

Read back an agent's published capabilities: `{agent, capabilities,
published_at, last_seen, published_by, session?}`; `404` if none published.
Readable by the owner, the agent itself, or an admin (the fleet-capacity
view) — else `403`.

### POST /v1/agents/{id}/heartbeat

Liveness ping: refresh `last_seen` **without** re-uploading capabilities —
the cheap "still here" signal, so a box that published once and runs for
hours stays a live host while a genuinely dead one ages out. Returns the
refreshed record. Same owner-or-self gate as publish; `404` for an unknown
agent **or** when nothing is published yet (publish before heartbeat); `422`
a malformed agent id.

### GET /v1/profiles/{id}/hosts

Match a `type: profile` node against every agent's published capabilities:

```
GET /v1/profiles/{id}/hosts?owner=me|person-jo&max_age=<dur>
```

Returns `{profile, satisfiable: [{agent, owner, published_at, last_seen,
age_seconds}], unsatisfiable: [{agent, owner, published_at, last_seen,
age_seconds, reasons}], counts}`. Satisfiable hosts are freshest-first (by
`last_seen`); unsatisfiable ones carry the matcher's own reasons (the failing
atoms), enabling substitution-free re-routing — pick a box that satisfies the
profile rather than substituting a different profile.

Visibility is steward-scoped: an **admin** sees the whole fleet and may scope
to any `owner=person-X`, while an ordinary **member** is scoped to their own
boxes (default `owner` is the caller's person; an agent token resolves to its
owner; `owner=me` is the explicit form) — asking for a colleague's is `403`.
`max_age` (`30m`, `12h`, `7d`, or milliseconds) demotes hosts whose
`last_seen` is older to unsatisfiable. An unknown or non-profile id is `404`;
a bad `max_age` or `owner` is `422`.
