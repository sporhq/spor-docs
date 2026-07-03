---
title: Reads
description: Status, identity, schema, briefings, nodes, history, changes, the queue, analytics, programs, and export.
sidebar:
  order: 3
---

All read endpoints are GET except `POST /v1/digest`, which is documented with
the [writes](/api/writes/#post-v1digest) because it shares the compile
pipeline. Non-2xx responses use the standard
[error envelope](/api/errors-and-compatibility/).

## GET /v1/status

Health check and graph summary:
`{node_count, projects: {...}, head, uptime, metrics}`. Add `?titles=1` for
`titles: [{id, type, project, title}]` — a one-round-trip index of the whole
graph, useful for client-side dedup.

```bash
curl -s https://api.sporhq.io/v1/status \
  -H "Authorization: Bearer $SPOR_TOKEN"
```

## GET /v1/me

Identity echo for the bearer token: `{person, name, email, bound, is_admin,
org}`.

- `bound: false` means the token authenticates but maps to **no person
  node** — routed questions and the personal queue will be empty, so treat it
  as a silent identity-degradation signal.
- `is_admin` reflects the `stewards → root` edge that gates the admin
  surface.
- `org` is the slug this tenant routes to (from `SPOR_ORG`, legacy
  `SUBSTRATE_ORG`, else `"local"`). Opaque `spor_oat_`/`spor_pat_` tokens
  carry no readable org claim, so clients use this echo to key their
  per-tenant credential store. A connector JWT's `org` claim is enforced
  equal to this echo.

## GET /v1/me/org-choices

Re-queries the identity provider's *current* org membership for the held
credential's subject: `{org_choices: [{slug, label, default?}], source:
"idp"|"bound"}`.

- `source: "idp"` is a true live enumeration — orgs added or removed since
  the last login surface without re-authenticating.
- `source: "bound"` means a single org-scoped token the server could not
  expand (no enumeration).

When the identity provider is unreachable the endpoint returns `502` with
`error.code: "membership_requery_failed"`. Clients treat only
`source: "idp"` as live and fall back to their cached tenant listing on
anything else, including a `404` from an older server.

## GET /v1/schema

The live schema registry as data — the contract itself, so clients never
have to reverse-engineer it:

```json
{
  "default_edge_weight": ...,
  "node_types": [{"type", "description", "prefix", "always_on", "traversable",
                  "capturable", "queueable", "non_resolving", "hooks",
                  "schema_id", "schema_version", "source"}],
  "edge_types": [{"type", "description", "weight", "weight_default",
                  "inverse_label", "aliases", "capturable", "hooks"}],
  "queue_policy": ..., "policies": ..., "registers": ...,
  "stale_overrides": ..., "alias_collisions": ...
}
```

The response is the seed pack merged with graph-resident `type: schema`
overrides, each entry tagged by `source` (`seed`/`graph`/`native`) plus the
active schema node's id and version. `?code=1` embeds each hook's source
under `code: {name: src}` (omitted by default to keep the response lean).

## GET /v1/briefing/{project}

Reads the project's briefing node: `{found, version, body, project_brief?,
graph_status}`.

The slug resolves through project-node aliases before lookup. A bare repo
slug also rides up to its home-project grouping: the grouping's briefing
returns alongside as `project_brief` (the product context spanning sibling
repos). Passing the repo node id (`repo-<slug>`) is the escape hatch that
returns only the repo brief.

Optional `?fp=root:<sha>,remote:<host/path>,...` carries the repo's
fingerprints: the server learns them onto the owning project node, and an
unknown slug with a known fingerprint files an alias proposal in the queue.

## GET /v1/nodes/{id}

One node: full raw markdown, parsed frontmatter, and `revision` (the version
identifier a later update must echo). Unknown id is `404`.

**Read-time enrichment** rides along as additive top-level keys the node's
active schema attaches — ignore keys you don't know:

- `resolution` — a live inbound `resolves`/`answers` edge carrying the
  resolver's `summary`/`title`, with a `lagging` flag when it contradicts a
  still-open status (clear once the node is terminal).
- `open_findings` — open maintenance findings about the node.
- `superseded_by` — set when an inbound `supersedes` edge marks the node
  stale.

```bash
curl -s https://api.sporhq.io/v1/nodes/task-api-rate-limits \
  -H "Authorization: Bearer $SPOR_TOKEN"
```

## GET /v1/nodes/{id}/history

Per-node commit lineage, newest first:

```json
{"id": "...", "head": "...", "count": N,
 "history": [{"sha", "short", "actor", "actor_name", "actor_email",
              "date", "message", "internal", "person"}]}
```

Each revision is labeled `internal: true` for a server-internal write (boot
reconciliation, migration) versus a real actor, and mapped to its `person`
node by author email. Because a node's `author` field re-stamps to the last
editor on every write, this endpoint is the only durable record of the full
chain of editors. `limit` defaults to 50, max 200. Unknown id is `404`; a
malformed id is `422`.

## GET /v1/nodes/{id}/history/{sha}

One revision's detail — the history record for that commit plus `{change,
patch, content}`: the change type (`A`/`M`/`D`/`R`), the patch that commit
introduced to the node, and the full node content at that revision (`null`
when the commit deleted it). The `sha` must come from the node's own history;
a sha that didn't touch the node, or an unresolvable sha, is `404`; a
malformed sha is `422`.

## GET /v1/commits/{sha}?repo=

Commit-sha-to-nodes lookup over the `commits:` fields — blame a line, get the
why. Accepts abbreviated or full shas (at least 7 hex characters); each match
carries `{repo, sha, id, type, title, summary, status, project}`.

## GET /v1/changes

The remote audit trail — what changed, and who or what changed it:

```
GET /v1/changes?since=&project=&limit=
```

Returns `{changes: [{id, change, commit, date, committed_by, type, title,
authored_via, author}], count, head, since, generated_at}`, newest change per
node first.

- `since` is a 7–40 hex commit sha (changes since that commit) or a
  date/relative phrase (`"12 hours ago"`, `"2026-06-15"`). An unresolvable
  sha is `422`.
- `project` scopes to one project's nodes (deletions are omitted when scoped,
  their project being gone).
- `limit` bounds nodes returned: default 100, max 500.

Each entry's `authored_via` is the machine-vs-human signal
(`capture`/`distill`/`gardener` are machine; anything else is human), so a
remote client can review what agents wrote without downloading the full
export.

## GET /v1/queue

The ranked decision queue:

```
GET /v1/queue?project=&assignee=&type=&exclude_type=&limit=&offset=
```

Returns `{items, count, offset, returned_count, total_count, truncated,
next_offset, counts_by_type, counts_by_project, counts_by_suggest, muted?,
dormant?, questions, asked, findings, pending, reviews, policy?,
generated_at}`.

Items already retired by a live inbound `resolves`/`answers` edge are
excluded whatever their status field reads; items hidden by the viewer's
mute list or parked by a future wake date are counted, never silently
dropped. The per-viewer side channels: `questions`/`findings`/`pending` are
the routed-to-me-plus-unrouted views for the authenticated identity, `asked`
is the questions you filed, and `reviews` is the nodes whose review is
requested of you (an open `review-requested` edge to your person node —
explicitly targeted, no unrouted fallback).

**Pagination.** `limit` is the page size (default 20, max 100 — clamped, not
rejected); `offset` skips that many items in the ranked order. The
`counts_*`/`total_count` aggregates always cover the **full** ranked set
regardless of the page, so one call answers "how many issues vs tasks"
without paging. Walk the queue by re-requesting with `offset=next_offset`
until `next_offset` is null. Pagination is an offset over a point-in-time
ranked slice, not a cursor: the queue re-ranks on every call, so across a
re-rank an item may be seen twice or skipped once — never a hard error.

**Scope filters** (applied before scoring, so the aggregates describe the
filtered queue):

- `project` — a bare repo slug unions its home-project grouping's member
  queues; `repo-<slug>` pins one repo; `proj-<slug>` uses a grouping
  directly. Omitting `project` is the cross-project firehose.
- `assignee=<person-id>` scopes to the work that person carries (their
  `assigned`/`stewards` edges); `assignee=me` binds to the caller (empty if
  the token maps to no person node).
- `type=`/`exclude_type=` (comma-separated, repeatable) whitelist/blacklist
  node types; exclude wins on overlap.

```bash
curl -s "https://api.sporhq.io/v1/queue?project=billing&limit=10" \
  -H "Authorization: Bearer $SPOR_TOKEN"
```

## GET /v1/analytics

Work-flow analytics over the graph, for remote clients with no local history
to fold:

```
GET /v1/analytics?project=&type=&weeks=&top=&aging=&format=
```

Default is the machine (JSON) report `{window, weekly, totals, throughput,
cycleTimeDays, wip, bottlenecks, coverage}`: weekly created / completed /
net / open-backlog cohorts, throughput, cycle-time median and p90, current
WIP by node type, and the oldest-open bottlenecks. `?format=text` renders the
human report.

Completion is a node's **status-transition time** — when it entered its final
terminal run — never its last-updated time, so a later edge append cannot
corrupt the "completed last week" signal.

`project` resolves like `/v1/queue` (bare repo slug unions its grouping;
`repo-<slug>`/`proj-<slug>` pin); a zero-match scope rides back as an
additive `project_warning` field. `type=` (comma-separated, repeatable)
restricts node types; `weeks`/`top`/`aging` shape the window (clamped to
1–52 / 1–100 / 1–365). A bad slug or type is `422`.

## GET /v1/metrics/capture

Capture-discipline aggregates for an **opted-in** deployment. Three gates
stack: a per-deployment opt-in (`SPOR_METRICS_EXPORT` — unset, the route
returns `404`, so a never-opted server shows no surface), admin auth
(`403` otherwise), and unconditional redaction. The body carries counts and
rates only: identities are stable per-tenant pseudonyms (`author-<hash12>`),
closure entries keep `{edge, latency_days}` but drop node ids, and id lists
reduce to counts. No journal lines, node bodies, or capture prose ever exit.
`?since=YYYY-MM-DD` bounds the window (malformed is `422`).

## GET /v1/program/{id}

The program/progress view — where a large workstream stands, derived on
demand from `blocks` topology with no lens authoring:

```
GET /v1/program/{id}?format=json|text&depth=&max_nodes=
```

Given a root node (an umbrella task, a milestone — anything other work
`blocks`), the server walks everything that blocks it transitively and
returns the gating tree with resolution-derived progress: `{progress:
{total, done, active, blocked, open, pct, statuses}}` on the view root.
"Done" means terminal status, supersession, or a live `resolves`/`answers`
edge — the same truth the queue uses, even while a status field lags. Shared
blockers render once and repeat as marked leaves, counted once.

JSON view tree by default; `?format=text` for the terminal rendering.
`depth`/`max_nodes` bound expansion and count skipped branches into
`truncated`, never silently. A root that nothing blocks is a successful empty
result; an unknown id is `404`.

## GET /v1/export

The data-exit path. By default, a ustar tarball of the graph's `nodes/`
directory, suitable for seeding a local read replica:

```bash
curl -s https://api.sporhq.io/v1/export?gzip=1 \
  -H "Authorization: Bearer $SPOR_TOKEN" | tar xz
```

- `?gzip=1` compresses the tarball.
- `?history=1` instead streams a git bundle of the whole graph repository
  (`application/x-git-bundle`, full commit provenance) — restore with
  `git clone <bundle> graph`.
- `?auth=1` also bundles the credential files so a disaster restore
  reproduces the credential set. Admin-gated: `403` without the
  `stewards → root` edge.

Response headers carry the graph state: `x-substrate-head` (graph commit)
and `x-substrate-node-count` (entry count), plus `x-substrate-skipped` when
any entry was omitted and `x-substrate-auth-files` on an `?auth=1` export. A
`?history=1` bundle carries only `x-substrate-head`. These legacy-spelled
header names are a deliberate wire contract — keep reading the
`x-substrate-*` spellings (see
[Errors and compatibility](/api/errors-and-compatibility/)).
