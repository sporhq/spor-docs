---
title: Writing to the graph
description: Capture, edit, and route work — plus claims, leases, and workflow runs.
sidebar:
  order: 6
---

The write surface has three layers. Prose in: `add` and `ask` accept free
text and produce well-formed nodes. Precise writes: `put-node`, `edge`,
`set-status`, `priority`, and `correct` change exactly one thing. Work
coordination: `claim`, `renew`, `extend`, and `release` manage the lease
that marks a task as in progress, and `run` starts a workflow.

### add

```
spor add "<text>" [--type T] [--title ...] [--project S] [--id <id>] [--during <id>] [--blocks <id>] [--needed-by <date>]
```

**Mode:** dual · **Alias:** `capture`

Capture a node from prose. In remote mode the server's ingestion model types
and links it; in local mode a well-formed, validated node file is written so
you never hand-author frontmatter (`--type`, `--title`, and `--id` apply to
local mode).

Capture context works in both modes: `--during <id>` links the node to the
work it was discovered during (a `derived-from` edge). `--blocks <id>` plus
`--needed-by <date>` declare a cross-project dependency — set `--project` to
the serving project (who must do the work) and it surfaces in their queue,
ramping urgency as the date nears.

```bash
spor add "Rate limits on the public API need per-org overrides" --type task
spor add "Platform must expose a token-rotation hook" --project platform --blocks task-api-rate-limits --needed-by 2026-08-01
```

### ask

```
spor ask "<question>" [--title ...] [--mention <id>] [--project S] [--id <id>]
```

**Mode:** dual · **Alias:** `question`

File a question the graph could not answer, so it becomes a routed node
instead of evaporating. In remote mode the server routes it to the steward
of the closest node in its relevance neighborhood, leaves it unrouted
(visible to everyone) when none matches, and attributes it to your token; in
local mode it writes an open, queueable question node so a solo user's
question still surfaces in `spor next`.

`--mention` names a node the question is about (repeatable; routing weighs
mentions first, and locally each becomes a `mentions` edge). `--project`
overrides the derived project — pass it for a mention-less question whose
neighborhood is empty. Answer a question by writing a node with an `answers`
edge to it, then `spor set-status <id> answered`.

```bash
spor ask "Did the token-rotation hook ship?" --mention dec-payments-stripe
```

### drain

```
spor drain [--limit <N>] [--timeout <S>]
```

**Mode:** remote · **Alias:** `sync`

Flush the fail-open capture spool to the team server. When a remote
`spor add` cannot reach the server, it spools the capture to the graph
home's outbox instead of losing it; `drain` replays each spooled file.
Shipped files are removed; permanent 4xx rejects (a revoked token, say) move
to `outbox/dead/` for inspection; transient failures stay spooled. A
successful remote `spor add` also drains opportunistically, so pure-CLI
usage self-heals without this verb. Exits 1 only when nothing could ship.
Local mode never spools — captures write straight to the graph.

```bash
spor drain --limit 10
```

### put-node

```
spor put-node [<file>|-] [--if-exists <error|skip|update>] [--revision <sha>] [--json]
```

**Mode:** dual

Create, skip, or update one complete node markdown file (frontmatter plus
body) through the validated full-node write path. With no file, or with `-`,
it reads the node from stdin.

Collision policy is explicit: `--if-exists error` (the default) rejects an
existing id, `skip` no-ops on collision, and `update` replaces an existing
node only when `--revision` matches the blob sha you read earlier — get it
with `spor get <id> --json`, and re-read and retry on conflict. Remote mode
applies server attribution, schema transition gates, edge normalization, and
validation; local mode validates the candidate before it lands on disk, so a
malformed node never does.

```bash
spor get dec-payments-stripe --json     # note the revision
spor put-node ./dec-payments-stripe.md --if-exists update --revision <blob-sha>
```

### edge

```
spor edge <id> <type> <to> [--attr <key=value>]
```

**Mode:** dual · **Alias:** `add-edge`

Add a typed edge from `<id>` to `<to>` — close a loop with `resolves`, mark
a dependency with `blocks`/`blocked-by`, or relate two nodes — without a
whole-node rewrite. The edge type must be known to the registry (canonical,
a rename alias, or an inverse form, which stores the canonical edge on the
other node); both ids must already exist, so create the target first.
Re-adding an existing edge is an idempotent no-op. `--attr key=value`
(repeatable) carries flat edge attributes.

```bash
spor edge dec-payments-stripe resolves task-api-rate-limits
```

### set-status

```
spor set-status <id> <status>
```

**Mode:** dual · **Alias:** `status-set`

Set a node's status. Setting a work node to an active status (`active`,
`open`, `in-progress`, or any status a schema maps to the active category)
also claims it in remote mode: the server takes the heartbeat lease that
keeps the item out of teammates' actionable queues, and the response reports
whether you hold it. A terminal status (`done`, `abandoned`, `resolved`, …)
leaves any claim untouched — release is its own op. The server runs the
type's status enum and transition gates, so for example `done` on a task
still needs a resolving decision or artifact. Local mode rewrites the status
in place; there is no claim pool locally.

```bash
spor set-status task-api-rate-limits active
```

### priority

```
spor priority <id> <p1|p2|p3|clear>
```

**Mode:** dual · **Alias:** `set-priority`

Set or clear a node's human-triage priority — the override half of the queue
blend, where `p1`/`p2`/`p3` bumps an item above the signal-ranked front
(`none`, `clear`, `p0`, or an empty value clears it). The change is stamped
with your identity and the door it came through, so an agent-set priority is
distinguishable from human triage.

```bash
spor priority issue-checkout-timeout p1
```

### correct

```
spor correct <target> [guidance] [--pin <id>] [--exclude <id>] [--guidance ...] [--title ...]
```

**Mode:** dual · **Alias:** `propose-correction`

Record a standing correction that fires at every future compile whose scope
includes the target. The target is a node id (fixes one topic's briefing),
`project:<slug>` (every compile for that project), or `global`. Pin a node
that was missed (`--pin`), exclude a stale one (`--exclude`) — both
repeatable, both must name existing nodes — and/or pass free-text guidance.

```bash
spor correct dec-payments-stripe "lead with the rollback plan, it is the binding constraint"
```

### claim

```
spor claim <node-id>
```

**Mode:** remote

Manually claim a task: take the heartbeat-renewed lease that marks it
yours-in-progress and keeps it out of teammates' actionable queues. Writes
the durable `assigned` edge once and creates the ephemeral server lease
(default TTL 45 minutes), attributed to you from your token — never an
argument. Re-claiming your own live claim just renews it; a live lease held
by someone else is refused, naming the holder and expiry. Local mode has no
claim pool, so it no-ops with a note.

```bash
spor claim task-api-rate-limits
```

### renew

```
spor renew <node-id>
```

**Mode:** remote

Heartbeat your live claim, bumping the lease expiry so it does not lapse
during a long stretch of work. No commit; the `assigned` edge is untouched.
A lapsed or stolen lease is refused, naming the current holder — renew never
re-creates a lapsed lease; that is a fresh `spor claim`.

```bash
spor renew task-api-rate-limits
```

### extend

```
spor extend <node-id> <duration>
```

**Mode:** remote

Extend your live claim by a duration, for a known long idle gap (a meeting,
overnight) where the default heartbeat window would lapse. The duration is
`2h`, `45m`, `30s`, `1d`, or a bare integer of milliseconds. The new expiry
is bounded by the org's maximum claim TTL: it never shortens a lease, and a
request past the ceiling is capped to it (reported on the result).

```bash
spor extend task-api-rate-limits 2h
```

### release

```
spor release <node-id>
```

**Mode:** remote

Hand a task back to the pool: drop the lease and retire the durable
`assigned` edge so a teammate can pick it up. Idempotent — releasing a task
you hold no lease on still cleans up any lingering `assigned` edge of yours.
Releasing a claim someone else holds is refused, naming the holder.

```bash
spor release task-api-rate-limits
```

### run

```
spor run <workflow-id> [--inputs <json>] [--json]
spor run status <run-id>
```

**Mode:** remote

Start or inspect a workflow run; workflow execution is server-side, so local
mode degrades with one line and no crash. `--inputs` is a JSON object
supplying the workflow's `${inputs.x}` values. Starting a run only creates
the workflow-run node and its initial step states — workers then claim ready
steps; it never executes effects. The workflow must already be active: a
proposed workflow must be activated by a different identity first (the
self-approval ban), else the start is refused with the reason.
`run status <run-id>` shows a run's state and per-step status.

```bash
spor run wf-release-pipeline --inputs '{"ref":"v1.2.0"}'
spor run status run-release-pipeline-20260701
```
