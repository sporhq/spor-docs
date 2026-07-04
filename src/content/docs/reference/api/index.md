---
title: REST API
description: The versioned HTTP contract — endpoints, authentication, and errors.
sidebar:
  order: 1
---

Everything the CLI and connectors do goes through one plain HTTPS + JSON API,
versioned under `/v1/` and authenticated with a bearer token on every route.
A REST endpoint and its MCP tool twin are thin adapters over the same core, so
the two surfaces return byte-identical payloads.

## Base URL and conventions

The base URL is your Spor server. Hosted teams use `https://api.sporhq.io`;
a self-hosted deployment uses its own origin. All routes are versioned under
`/v1/` (the OAuth routes used for sign-in sit at `/oauth/*` — see
[Authentication](/reference/api/authentication/)).

- **Auth**: send `Authorization: Bearer <token>` on every request. Transport
  is HTTPS only. See [Authentication](/reference/api/authentication/) for token kinds.
- **Content type**: request and response bodies are JSON. Request bodies are
  capped at 1&nbsp;MB (`413 too_large`).
- **Path parameters** (node ids, project slugs) must match
  `^[a-z0-9][a-z0-9-]*$`.
- **Errors**: every non-2xx response carries a
  `{"error": {"code", "message", "details"}}` envelope. See
  [Errors and compatibility](/reference/api/errors-and-compatibility/).

```bash
curl -s https://api.sporhq.io/v1/status \
  -H "Authorization: Bearer $SPOR_TOKEN"
```

## Client configuration

Two environment variables switch a Spor client into remote mode; unset, it
reads the local graph home directly. The legacy `SUBSTRATE_*` spellings are
still read (see [Errors and compatibility](/reference/api/errors-and-compatibility/)).

```
SPOR_SERVER=https://api.sporhq.io   # REST base (the hosted default)
SPOR_TOKEN=spor_pat_...             # per-user token
SPOR_ORG=acme                       # select a stored tenant by org
```

`spor join <token>` writes the first two for you, defaulting `SPOR_SERVER`
to the hosted base; pass a URL (`spor join <url> <token>`) to point at a
self-hosted server instead.

## Write semantics

Every mutation is validated, attributed, serialized, and committed to the
graph's version history. Attribution is stamped from the authenticated token
(any `author:` in the payload is discarded), updates require the `revision`
you read (a mismatch is a `409 conflict` — re-read and retry, no silent
last-write-wins), and validation failures return the validator's error list
verbatim so a calling program can self-correct. The full contract is on
[Writes](/reference/api/writes/).

## Endpoints

### [Reads](/reference/api/reads/)

| Method | Path | Purpose |
|---|---|---|
| GET | `/v1/status` | health, node count, projects, graph head |
| GET | `/v1/me` | identity echo for the bearer token |
| GET | `/v1/me/org-choices` | live org membership for the held credential |
| GET | `/v1/schema` | the live schema registry as data |
| GET | `/v1/briefing/{project}` | a project's briefing node |
| GET | `/v1/nodes/{id}` | one node, with read-time enrichment |
| GET | `/v1/nodes/{id}/history` | per-node commit lineage |
| GET | `/v1/nodes/{id}/history/{sha}` | one revision's patch and content |
| GET | `/v1/commits/{sha}` | commit sha → the nodes that reference it |
| GET | `/v1/changes` | recent changes to the graph (audit trail) |
| GET | `/v1/queue` | the ranked decision queue |
| GET | `/v1/analytics` | created-vs-completed work-flow analytics |
| GET | `/v1/metrics/capture` | opt-in, redacted capture-discipline aggregates |
| GET | `/v1/program/{id}` | program/progress view over `blocks` topology |
| GET | `/v1/export` | tarball, history bundle, or auth backup — the data-exit path |

### [Writes](/reference/api/writes/)

| Method | Path | Purpose |
|---|---|---|
| POST | `/v1/digest` | digest-mode compile for prompt context |
| POST | `/v1/nodes` | put nodes (batch) |
| POST | `/v1/nodes/{id}/edges` | add one typed edge |
| DELETE | `/v1/nodes/{id}/edges` | remove one typed edge |
| POST | `/v1/nodes/{id}/status` | one-scalar status update |
| POST | `/v1/nodes/{id}/priority` | human priority override |
| POST | `/v1/nodes/{id}/commits` | link a code commit to a node |
| POST | `/v1/capture` | raw text in, typed nodes out |
| POST | `/v1/distill/report` | sweep telemetry (journal-only) |
| POST | `/v1/corrections` | propose a standing briefing correction |
| POST | `/v1/questions` | file a routed question |
| POST | `/v1/gardener` | run a maintenance sweep now |

### [Leases](/reference/api/leases/)

| Method | Path | Purpose |
|---|---|---|
| POST | `/v1/nodes/{id}/claim` | take the heartbeat-renewed lease |
| POST | `/v1/nodes/{id}/renew` | heartbeat: bump the lease expiry |
| POST | `/v1/nodes/{id}/extend` | stretch a live lease for a long idle gap |
| POST | `/v1/nodes/{id}/release` | drop the lease, return the node to the pool |

### [Lenses and sharing](/reference/api/lenses-and-sharing/)

| Method | Path | Purpose |
|---|---|---|
| GET | `/v1/lens/{id}/render` | render a lens or workspace (html, text, json) |
| POST | `/v1/lens/{id}/ticket` | mint a read-only, expiring share ticket |

### [Tokens and agents](/reference/api/tokens-and-agents/)

| Method | Path | Purpose |
|---|---|---|
| GET / POST | `/v1/me/tokens` | list / mint your own personal access tokens |
| DELETE | `/v1/me/tokens/{hash-prefix}` | revoke one of your own tokens |
| GET / POST | `/v1/admin/tokens` | team-wide token list / mint (admin) |
| DELETE | `/v1/admin/tokens/{hash-prefix}` | revoke any token (admin) |
| GET / POST | `/v1/agents` | list / create agents you own |
| POST | `/v1/admin/agents` | create an agent for another person (admin) |
| POST | `/v1/agents/{id}/token` | mint a per-session or standing agent token |
| GET | `/v1/agents/{id}/tokens` | list an agent's standing tokens |
| DELETE | `/v1/agents/{id}/tokens/{hash-prefix}` | revoke one standing agent token |
| POST | `/v1/agents/session` | late-bind a run session to an agent token |
| POST / GET | `/v1/agents/{id}/capabilities` | publish / read machine capabilities |
| POST | `/v1/agents/{id}/heartbeat` | liveness ping without a re-publish |
| GET | `/v1/profiles/{id}/hosts` | match a profile against published capabilities |

### [Workflow runs](/reference/api/workflow-runs/)

| Method | Path | Purpose |
|---|---|---|
| POST | `/v1/workflows/{id}/run` | start a run of an active workflow |
| GET | `/v1/work` | claimable steps across live runs |
| POST | `/v1/runs/{id}/steps/{sid}/claim` | claim a ready step |
| POST | `/v1/runs/{id}/steps/{sid}/complete` | report a step verdict |
| GET | `/v1/runs/{id}` | the full run record |
