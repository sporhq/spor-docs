---
title: Reading the graph
description: Query, rank, inspect, and export nodes — the read half of the graph verbs.
sidebar:
  order: 5
---

The read surface, from broadest to narrowest: `next` ranks open work,
`query` enumerates by filter, `get` prints one node, `history` and `blame`
follow the git trail, `changes` shows what landed recently, `analytics`
folds it into metrics, `schema` introspects the type registry, `lens` and
`share` render saved views, and `export` streams the whole graph out.

Most of these are dual-mode with matching output in both modes: local mode
reads the graph home on disk, remote mode reads the team server.

### next

```
spor next [--project S | --all-projects] [--type T] [--exclude-type T] [--limit N] [--json] [--hide-dispatched]
```

**Mode:** dual · **Alias:** `queue`

Show the ranked decision queue — open work ordered by graph signal and
human-set priority.

Scope: `--project` accepts a repo slug, a `repo-<slug>` node id, or a
grouping id; an unknown token warns and yields an empty queue. Pin a default
scope with the `queue.project` config key (`SPOR_QUEUE_PROJECT`, or
`.spor.json` `{"queue": {"project": "..."}}`); an explicit `--project` still
wins. `--all-projects` (alias `--all`) widens to the whole-graph firehose.

Page size: `--limit N` caps the list (default 20); `--limit 0` shows all.
The aggregate counts always describe the full ranked set regardless of the
page.

Types: `--type` and `--exclude-type` whitelist and blacklist node types.
Both are repeatable and comma-splittable; exclude wins on overlap.

Readiness: local mode's `--readiness <agent|human|untriaged>` (repeatable,
comma-splittable — `--readiness agent,untriaged`) narrows the queue to items
carrying that derived [agent-readiness](/reference/graph-model/node-types/#agent-readiness)
classification. When the graph has any readiness signal, local text output
also prints a lead line, `readiness: N agent-ready, N need human, N
untriaged`, and `--json` carries the same breakdown as `counts_by_readiness`.
The server's [`GET /v1/queue`](/reference/api/reads/#get-v1queue) and the
[`show_queue`/`render_queue`](/reference/mcp/tools/#show_queue) MCP tools
expose the identical filter and fields — this CLI's remote `next` does not
yet forward `--readiness` or print the lead line, so reach for the REST or
MCP surface directly for a readiness view over a team graph.

In-flight: `--json` stamps each item with an `in_flight` flag (and a
`dispatched` agent summary) by cross-referencing live background agents —
[`spor dispatch`](/reference/cli/dispatch/#dispatch) names each agent after its node
id. `--hide-dispatched` drops items that already have an agent in flight.
Both are client-side and fail soft when the `claude` binary is absent.

Local mode also accepts `--days`, `--no-front`, `--name-only`, and
`--nodes`.

```sh
spor next --project billing --type task,issue --limit 50
```

### get

```
spor get <id> [--json]
```

**Mode:** dual

Print one node's raw markdown by id; a missing node exits 1. `--json` emits
a structured object — `{id, frontmatter, body, edges: {outbound, inbound},
revision}` — so scripts stop scraping frontmatter. `revision` is the value
an update sends (see [`put-node`](/reference/cli/writing-to-the-graph/#put-node)).
Inbound edges are gathered by scanning the whole graph, so `--json` is
heavier than the plain read.

The plain-text form (not `--json`) also prints a `note:` line on stderr,
after the node's raw markdown, when the fetched node is currently [HELD by a
controller-completion execution
hold](/reference/factory/#controller-completion-the-resolving-edge-written-at-a-declared-boundary):
which execution holds it, whether its worker reads live, **STALE**, or
elsewhere, and the door out (`spor release <id> --execution <exec>`, or
waiting for the controller's own completion write).

```sh
spor get dec-tidefall-billing-retries --json
```

### query

```
spor query [--type T] [--where k=v] [--id-prefix <p>] [--edges] [--edge-type T] [--from <id>] [--to <id>]
```

**Mode:** dual

Deterministic, filterable enumeration over the graph — the structured list
that `get` (one node), `next` (the ranked queue), and `compile --query`
(semantic search) are not. Pure, no LLM. Remote mode runs the same
enumeration over the team graph.

Node selection ANDs across distinct flags: `--type` (repeatable, OR within
type), `--where key=val` (repeatable, AND; a list field such as `tags`
matches on membership), `--id-prefix`.

`--edges` switches output from nodes to `{from, type, to}` edges, restricted
by `--edge-type`, `--from`, and `--to`; the node predicates then restrict
each edge's source.

Projection: default table, or `--ids`, `--summary`, `--full`, `--json`.
`--nodes <dir>` points at a local checkout even under a server.

```sh
spor query --where status=open --type task --json
```

### blame

```
spor blame <sha> [--repo <slug>] [--json]
```

**Mode:** dual · **Alias:** `commits`

Reverse-lookup a git commit to the decision, task, and issue nodes that
reference it in their `commits:` field — blame a line, get the why. The sha
is 7–40 hex characters, abbreviated or full, matched prefix-aware. An empty
result is normal (a commit linked to no node) and exits 0.

```sh
spor blame b384469 --repo billing
```

### history

```
spor history <id> [<sha>] [--limit N] [--content] [--json]
```

**Mode:** dual

Show one node's commit history — every revision's actor, time, and what
changed. The frontmatter `author` field re-stamps to the last editor on
every write, so git history is the only durable record of the full chain of
editors. With a `<sha>`, show that revision's diff and change type;
`--content` adds the full node at that revision. `--limit` caps the list
(default 50, max 200). Output matches across modes.

```sh
spor history dec-tidefall-billing-retries --limit 10
```

### changes

```
spor changes [--since <sha|date>] [--project S] [--limit N] [--json]
```

**Mode:** dual

The recent-activity feed: what landed, what the agents wrote overnight, what
changed since a commit. One entry per node — its newest change in range,
newest first — each tagged machine (capture, distill, gardener) versus
human. `--since` takes a sha (unresolvable is an error) or any date or
relative phrase git understands (`'12 hours ago'`, `2026-06-15`). `--limit`
defaults to 100, max 500. `--nodes <dir>` reads a local checkout.

```sh
spor changes --since '12 hours ago' --project billing
```

### check

```
spor check [--staged | --range <a..b> | --files <f...>] [--strict] [--json]
```

**Mode:** dual

Check a change set against the graph's [coupling
norms](/reference/graph-model/node-types/#coupling-norms): report each norm
whose trigger globs are touched while its target artifacts are not, and each
declared value invariant whose two extracted values disagree. The change set
is always local git — everything uncommitted plus untracked files by
default, `--staged` for the index only, `--range` for a commit range (value
invariants read the range's newer side), `--files` for an explicit list.
Targets that live in another repository are listed as reminders, never
failures. Advisory by default; `--strict` exits 1 when findings exist, which
is the CI and pre-commit shape.

```sh
spor check --range origin/main..HEAD --strict
```

### analytics

```
spor analytics [--project S] [--type T] [--weeks N] [--top N] [--aging N] [--json]
```

**Mode:** dual

Work-flow metrics over the git-derived timestamp index: created versus
completed work per ISO week, throughput, cycle time, current WIP by type,
and the oldest-open bottlenecks. Completion time is a node's
status-transition time derived from git content history, never `updated_at`
(which a later edge append would push past completion); a non-git home falls
back to frontmatter dates. `--weeks` sets the cohort window (default 12),
`--top` the bottleneck list length (default 10), `--aging` the aging-WIP
threshold in days (default 30).

```sh
spor analytics --project billing --type task,issue --weeks 8
```

### schema

```
spor schema [<type>] [--edges] [--nodes-only] [--source <s>] [--code] [--json]
spor schema candidates [--json]
spor schema adopt <schema-id> [--activate] [--force]
```

**Mode:** dual

Introspect the live schema registry — every node and edge type with its id
prefixes, edge weights, ride-along flags, the status-resolution partition,
and the attached `validate()`/`transitions()`/`get()` gates. Merges the seed
pack with graph-resident `type: schema` overrides and tags each entry's
provenance (`seed`, `graph`, `native`); query this rather than reading seed
files, which miss resident overrides. With a `<type>`, print that type's
detail including each hook's source. `--source` filters by provenance;
`--code` includes hook source in `--json` output.

Two reserved subcommands manage the **candidate pack** — rollout-stage
schemas that ship with the npm package but stay inert until a graph adopts
them as graph-resident schema nodes (see
[Schemas → The candidate pack](/reference/graph-model/schemas/)):

- `spor schema candidates` lists each packaged candidate with its adoption
  state against the active graph (`not adopted`, `current`, upgradable,
  locally modified, or promoted to the seed pack). The plain `spor schema`
  overview also appends a one-line footer whenever unadopted candidates
  exist.
- `spor schema adopt <schema-id>` writes a candidate into the active graph
  through the validated node surface (never a raw file drop). A fresh adopt
  lands `status: proposed`; `--activate` writes `active` — the trusted-admin
  form for solo/local graphs (team graphs activate through the normal
  review flow). Re-running after a package upgrade is idempotent and
  CalVer-aware: a pristine older copy upgrades in place with its status
  preserved, while a locally modified (or hand-copied, unstamped) resident
  refuses without `--force`.

```sh
spor schema task
spor schema candidates
spor schema adopt schema-edge-member-of-program --activate
```

### lens

```
spor lens [<id>] [--format <text|json>] [--json]
```

**Mode:** remote · **Alias:** `render-lens`

Render a saved lens; lenses render server-side. With no id, list the lens
catalog. Any extra `--PARAM VALUE` flags beyond `--format`/`--json` are
forwarded to the lens as render parameters.

```sh
spor lens lens-tidefall-retry-radar --project billing
```

### share

```
spor share <lens-id> [--expires <Nd>] [--json]
```

**Mode:** remote

Mint a signed, expiring, read-only render ticket for a lens or workspace
node and print the shareable view link. The ticket records you as the
sharer, binds the viewer to that identity (the render shows a "Viewing as"
banner), and carries no write scope, so a pasted link can never leak a
write-capable credential. `--expires` is `<N>d` or an ISO date (server
default 7d, max 30d). Your token must be bound to a person node.

Against an MCP-only server the printed link points at the app host instead
of the render route — see [`url` on an MCP-only
host](/reference/api/lenses-and-sharing/#url-on-an-mcp-only-host) — and a
live session on that app host outranks the ticket, so a signed-in recipient
always sees their own session rather than the sharer's view.

```sh
spor share lens-tidefall-retry-radar --expires 14d
```

### export

```
spor export [--gzip] [--history|--auth] [--out <file>]
```

**Mode:** dual (`--history` and `--auth` are remote-only)

Stream the graph's `nodes/` as a POSIX ustar tarball, for seeding a local
read replica or bootstrapping a fresh graph from a snapshot. Output goes to
`--out` or to stdout so it pipes straight into tar; the node count, size,
and graph head ride stderr so they never pollute a piped tarball. `tar x`
reproduces `nodes/` byte-for-byte in either mode.

Two further modes are remote-only and mutually exclusive: `--history`
produces a git bundle of the whole graph repository with full commit
provenance (the data-exit path; `git clone <bundle> graph` reproduces the
history), and `--auth` is an admin-gated backup that also bundles the
credential set for disaster restore.

```sh
spor export --gzip | tar xz
spor export --history --out graph-history.bundle
```
