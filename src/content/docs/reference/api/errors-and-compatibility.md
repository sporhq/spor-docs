---
title: Errors and compatibility
description: The error envelope, the full code table, retry guidance, and the back-compat window.
sidebar:
  order: 9
---

## The error envelope

Every non-2xx response carries one shape:

```json
{ "error": { "code": "...", "message": "...", "details": [...] } }
```

`code` is the stable, machine-readable identifier; `message` is for humans;
`details` carries structured extras where an endpoint documents them (for
example, a validator's error list, or the allowed values for a rejected
priority).

## Error codes

| Code | HTTP status | Meaning |
|---|---|---|
| `unauthorized` | 401 | missing, invalid, expired, or revoked token |
| `forbidden` | 403 | authenticated, but the route needs the admin gate, an ownership gate, or a bound person node |
| `not_found` | 404 | unknown node, route, or resource |
| `conflict` | 409 | id collision on create, revision mismatch on update, or a lease held by someone else |
| `transition_denied` | 409 | the active schema's transition gate refused the status change; the message carries the gate's reason |
| `lease_expired` | 409 | a workflow step's lease expired or was superseded |
| `outcome_conflict` | 409 | a same-generation step retry disagrees with the recorded outcome — redo under a fresh lease |
| `not_ready` | 409 | the resource is not in a claimable/actionable state |
| `invalid_node` | 422 | validation failure; `details` carries the validator's errors verbatim |
| `too_large` | 413 | request body over the 1 MB cap |
| `rate_limited` | 429 | back off and retry |
| `ingestion_unavailable` | 503 | the capture path's ingestion model is unreachable |
| `unimplemented` | 501 | the route exists but is not implemented on this server |
| `internal` | 500 | server fault |

## Retries

A `429 rate_limited` response should carry a `Retry-After` header (delay
seconds or an HTTP-date); honor it, otherwise back off exponentially with a
cap before retrying.

Mechanical writers that replay queued requests classify `401`, `400`, `413`,
and `422` as **permanent** — a revoked token will not un-revoke, an oversized
body will not shrink — and dead-letter them rather than re-POSTing forever.
`429` and `5xx` stay transient and are retried with backoff.

Spor's own client hooks go one step further: any non-200 means "behave as if
the graph is empty". Fail open, never block a session.

## The back-compat window

Spor was renamed from an earlier product, and every user-facing contract
dual-reads the old spellings. No re-mint or client change is required:

| Surface | Current | Legacy (still accepted) |
|---|---|---|
| Personal access tokens | `spor_pat_...` | `sub_pat_...` |
| OAuth access tokens | `spor_oat_...` | `sub_oat_...` |
| Client environment | `SPOR_SERVER`, `SPOR_TOKEN`, `SPOR_ORG` | `SUBSTRATE_SERVER`, `SUBSTRATE_TOKEN`, `SUBSTRATE_ORG` |

The `/v1/export` response headers (`x-substrate-head`,
`x-substrate-node-count`, `x-substrate-skipped`, `x-substrate-auth-files`)
keep their legacy spelling deliberately — they are a wire contract and were
not renamed. Keep reading the `x-substrate-*` names.
