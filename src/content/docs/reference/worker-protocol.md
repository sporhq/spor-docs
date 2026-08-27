---
title: Worker protocol
description: The claim, brief, work, report, resolve loop a background agent runs, specified precisely enough that a third party can implement a conforming worker without the Spor client.
---

**Use this when** you are building a worker that runs queue items without
going through `spor dispatch` — a custom launcher, a different harness
adapter, or a headless polling process — and need the exact contract it must
honor against the graph.

**You do not need this if** `spor dispatch` already does this for you; see
[Dispatch, capabilities, and profiles](/reference/dispatch/) instead.

**After reading this, you should be able to** implement the claim → brief →
work → report → resolve loop against plain REST calls, and know exactly what
makes a run `resolved`, `reported`, or `failed`.

Spor is the durable substrate of a software factory, not the factory
itself. A coding-agent harness — Claude Code, Codex, OpenCode, GitHub
Copilot CLI, or anything else that can read a prompt and write code — is a
fungible **worker** behind a protocol specified precisely enough that a
third party can implement a conforming worker without the Spor client.
Everything below reduces to plain REST calls plus the sequencing and shapes
those calls compose into. `spor dispatch`/`spor work` are **one reference
implementation** of this protocol, not the protocol itself — new harnesses
are additive adapters, never a fork of the orchestration layer.

## What a worker is

A worker is any process that, over one unit of work:

1. **claims** a node from the queue ([The pool and the claim](#the-pool-and-the-claim)),
2. **reads** the compiled context for it ([The prompt contract](#the-prompt-contract)),
3. **does the work** — out of this protocol's scope: write code, run tests,
   whatever the task requires,
4. **reports** back onto the graph in exactly one of three terminal shapes
   ([Terminal states](#terminal-states-the-outcome-contract)), and
5. **releases** the lease so the item returns to (or leaves) the pool, in an
   order that can never lose the work.

Nothing here requires the Spor CLI, the Claude Code plugin, or any
particular model. A worker is identified to the graph by an **agent node**
carrying its own bearer token; every write it makes is attributed through
that token, independent of which binary is doing the writing.

## Agent identity and attribution

A worker writes to the graph as an **agent** node — a person-owned
principal, not a person. Every write under an agent-scoped token is stamped
`authored_by_agent: <agent-id>` and `session: <id>`, with `authored_via:
dispatch`; `author:` stays the agent's owning person, so the node reads
"agent on behalf of person." This is the token a worker process should
hold — never a person's own account-scoped token or connector session,
which would attribute the work to the human instead of the agent that did
it.

**No agent identity resolves, or minting one fails?** On a real remote
dispatch, this hard-fails, naming the fix (`spor agent use <agent-id>`) —
never a silent fall back to a person-scoped token, which is exactly the
human step agent attribution exists to keep out of the loop. Unlike the
readiness-gap split in [The pool and the claim](#the-pool-and-the-claim),
this one isn't locked to a surface: both `spor dispatch` and the autonomous
`spor work` loop refuse by default, and both accept the same explicit
escape hatch — `--allow-person-token` (the standing `dispatch.allowPersonToken`
config key, or the `SPOR_ALLOW_PERSON_TOKEN` env var) — with a loud warning
on every fallback launch it permits. The escape hatch exists for solo/local
use where nobody has bothered to mint a machine identity and that's a
deliberate choice, not an accident; leaving it unset is what keeps an
unattended worker from ever silently misattributing agent work to the
person that happens to own its token. Local mode is unaffected — there is
no CA to mint an agent token against.

Minting and managing this identity — the two token shapes (per-session and
standing), and late session binding when the harness's real session id
isn't known at mint time — is the full subject of [Tokens and
agents](/reference/api/tokens-and-agents/#agents). A worker only needs to
know: hold an agent-scoped token, and if your launcher can't know the
harness's session id up front, bind it once the harness reports it via
`POST /v1/agents/session` rather than guessing or omitting it forever.

## The pool and the claim

`GET /v1/queue?project=<slug>` returns the ranked, live queue for a
project. Each item's `readiness` field (`agent`/`human`/`untriaged`) says
whether it is meant for an autonomous worker at all — `readiness: human`
always wins over any stamp, and a worker should never claim it. `suggest`
on each item (`do`/`dispatch`/`blocked`/`triage`/`close`/`approve`) is a
further hint; `blocked` means a live `blocks` edge still gates it — claiming
it is legal but the item cannot resolve until its blocker does. See
[Agent-readiness](/reference/graph-model/node-types/#agent-readiness) and
[The decision queue](/use-spor/queue/) for what drives both fields.

Before starting work, take the heartbeat-renewed lease:

```
POST /v1/nodes/{id}/claim {session?, dispatch?}
```

This writes the durable `assigned` edge once (attributed to the
authenticated identity — never a body field) and creates an ephemeral
lease. `expires_in_ms` in the response is the renewal horizon *relative to
when this call ran* — a worker should renew at roughly half of it, never
hardcode a TTL, since the bound is graph-resident tenant policy and varies
per repo. A live lease held by someone else is `409 conflict` naming the
holder and expiry; re-claiming your own live lease is an idempotent renew.

`dispatch` is an optional opaque nonce a launcher can tag its claim with so
the server can tell **a second concurrent launch of the same node by the
same identity** apart from an idempotent re-claim/renew — without it, a
same-identity double-launch just renews and silently starts two workers on
one node. Pass a fresh value (e.g. a UUID) per launch attempt; omit it for
a deliberate re-attach to an already-running claim.

The full lease family — `renew`, `extend`, `release`, `reserve`, and their
bulk working-set twins — is documented on [Leases](/reference/api/leases/).
The one fact worth repeating here: a crashed worker needs to do nothing.
The lease is **read-time self-healing** — a lapsed lease demotes the claim
and the node re-enters the pool with zero sweep and zero scheduler.

## The prompt contract

A worker's context is assembled from three parts, in this order — this is
the shape `spor dispatch` builds, and the one a third-party launcher should
reproduce so a worker sees the same standing context regardless of harness:

```
> **Spor session project:** `<slug>`. If you file a question with
> `ask_question` (or `POST /v1/questions`) that has no clear `mentions:`,
> pass `project: "<slug>"` so it is stamped to this project rather than
> defaulting to the asker's home project.

# Spor briefing (compiled for this task — your standing context)

<compiled neighborhood — from POST /v1/digest {root: <node-id>} or query>

---

# Task

Work on <node-id> — <title>. The compiled Spor briefing above is your
standing context. <any additional free-text task instructions>
```

1. **Session note.** One paragraph naming the session's project slug, so a
   worker filing a mention-less question stamps it correctly instead of
   defaulting to the asker's home project.
2. **Compiled briefing.** `POST /v1/digest {root: <node-id>}` (or `{query:
   <text>}` for a free-text task with no target node) returns the node's
   neighborhood: prior decisions, constraints, dismissed approaches, related
   work — the same compiler behind [Briefings and
   corrections](/use-spor/briefings/). This section can be omitted entirely
   for a bare-bones launch, but every worker benefits from including it.
3. **Task.** What to do — the target node's id and title plus any additional
   instruction text, or free-text task instructions with no node at all.

There is no wire-level requirement that a worker consume this exact string;
what matters is that a conforming worker (a) is capable of reading a
compiled briefing before acting non-trivially, and (b) knows which node it
is working on, so its terminal report can name it.

## Capability declaration (optional)

A worker box may **publish** what it can run so a routing layer can pick a
satisfying host instead of a human hardcoding one — harnesses, reachable
MCP servers, skills, and plugins, matched atomically against a `profile`
node's runtime fields, with no silent substitution when a box can't satisfy
one. This is entirely optional: a worker that never publishes capabilities
simply never appears in a host lookup, and nothing above depends on it. Full
detail — the publish/read/heartbeat routes and host matching — is on
[Tokens and agents](/reference/api/tokens-and-agents/#capabilities-and-host-matching);
the profile side of the match is on [Dispatch, capabilities, and
profiles](/reference/dispatch/#profiles-the-how-factored-out).

## Terminal states: the outcome contract

This is the contract every worker must honor, however it is launched. It
answers a question the process's own exit code cannot: **what did this run
actually do to the graph** — an agent can exit 0 having done nothing, and
one that crashed after writing its resolver still finished the job.

`terminal_state` is exactly one of:

| Value | Means | How it's earned |
| --- | --- | --- |
| `resolved` | the target is genuinely done | re-reading the graph shows a **live inbound `resolves`/`answers` edge** onto the target node |
| `reported` | not done, but the work reached the graph | no resolving edge, but the worker's final report was filed as an artifact `relates-to` the target |
| `failed` | nothing usable reached the graph | no resolving edge and no usable report |

**`resolved` is a graph read, never an exit code, never the worker's own
claim.** Re-fetch the node — `GET /v1/nodes/{id}` — and check its
`resolution` enrichment: a live, visible, inbound `resolves` or `answers`
edge, carrying the resolver's id. Its absence is the answer for a worker
that *claims* success without writing one — that absence reads as
`reported` or `failed`, never `resolved`. This is the single most important
rule in this protocol: **a worker's own "I'm done" is not evidence; a
resolving edge on the graph is.**

**Report presence — not exit status — discriminates `reported` from
`failed`.** A run that crashed midway but had already produced a usable
final report is `reported`, not `failed`; the crash itself is a separate,
process-level fact, never conflated with the outcome. The invariant a
consumer keys on: whenever a report artifact id is present, `terminal_state`
is `reported` — always, whether the verdict was fully verified or not (see
unverifiable targets below).

**Unverifiable targets.** Only node types whose completion is a *resolving
edge* rather than a status flip — `task`, `issue`, `question`, `incident` —
can be judged for `resolved` at all. A `decision` or `finding` target
(closed by status, not by edge) is out of scope for the verdict: the filed
report's wording says "not verified" instead of "ended without resolving
it," and `terminal_enforced` reads `false` even when a report was filed.
This type also changes the ordering below: the lease is never released on
the strength of a verdict this contract cannot make — not on a successful
report filing, and not on a missing one either. It is left to lapse at its
own TTL in both cases.

**Ordering is the contract: file the report, then release the lease —
never the other way, and never both-or-neither on a failure.**

1. Re-read the target node; a live resolving edge → done, **`resolved`**,
   release nothing (the durable `assigned` edge already stands as the
   record of who did the work).
2. Target is an **unjudgeable type** (`decision`/`finding`) → file the
   report if text exists, worded "not verified"; **release nothing either
   way** — `terminal_state` reads `reported` if a report was filed or
   `failed` if there was none, but always with `terminal_enforced: false`
   and the lease left to lapse at its TTL.
3. Judgeable type, no resolving edge, a final report text exists → **file it
   as an artifact** (see [The report artifact](#the-report-artifact)). If
   the write lands (or was already there — filing is idempotent), release
   the lease → **`reported`**. If the write is *refused* by the graph, the
   lease is deliberately left **held** rather than releasing a signal-free
   item back into the pool — it lapses at its own TTL instead.
4. Judgeable type, no resolving edge, no report text at all → release the
   lease → **`failed`**, with a `terminal_note` explaining why.

A crash between step 3's two writes can therefore only ever leave the lease
held with the report already filed, or leave both undone — **never** a
released lease with no report to show for it.

**What "enforced" means, and where it doesn't apply yet.** `terminal_state`
is only as trustworthy as `terminal_enforced` says it is: it is `true` only
when the graph was actually re-read against a reachable server — and, for a
target with no resolving edge, the report actually filed there too (a
`resolved` verdict needs only the re-read; nothing is filed once a
resolving edge is already found). Every other case — no team graph
configured (local-mode dispatch), a free-text dispatch with no target node,
an unreachable server, an out-of-scope target type (above), or a
native-background launch whose termination this runner cannot
deterministically observe — stamps `terminal_enforced: false` and can never
read `resolved`. A `reported` or `failed` value on an unenforced record is
a best-effort classification of the *process* outcome, not a checked
verdict; `terminal_enforced` is the field a consumer must gate on before
treating either as ground truth.

### What a third-party (non-reference-client) worker must do

If your launcher is not `spor dispatch`/`spor work`, reproduce the
algorithm above directly against REST once your worker process ends:

```
1. GET  /v1/nodes/{targetId}
2. if resolution.by present               → terminal_state = resolved; done, no release
3. elif targetId's type is decision/finding (an unjudgeable type)
                                           → if final report text exists: POST /v1/nodes (file it, if_exists: skip)
                                                → terminal_state = reported, terminal_enforced = false
                                             else
                                                → terminal_state = failed, terminal_enforced = false
                                             NEVER release the lease either way — it lapses at its own TTL
4. elif final report text exists          → POST /v1/nodes  (file the report, if_exists: skip)
                                             if the write lands: POST /v1/nodes/{leaseNode}/release
                                                                  → terminal_state = reported
                                             if the write is refused: leave the lease held
                                                                  → terminal_state = failed (held)
5. else                                   → POST /v1/nodes/{leaseNode}/release
                                             → terminal_state = failed
```

`leaseNode` is whichever node your claim actually established the lease
on — normally the same as `targetId`, but not necessarily (a forced
re-dispatch that renewed someone else's lease releases nothing, since that
lease isn't yours to hand back).

## The report artifact

The filed report is an ordinary `artifact` node, deliberately **not** a
resolver — it carries `relates-to`, never `resolves`, because filing a
report must never itself retire the item; the whole point is the work
returns to the queue *carrying* the report rather than vanishing.

```markdown
---
id: art-dispatch-report-<stem>-<short-run-id>
type: artifact
project: <slug>              # when known
title: Dispatch report — <target-node-id>
summary: Final report from the dispatched <harness> run on <target>, <ended without
  resolving it | whose outcome was not verified against the graph>: <first line of report>
date: <YYYY-MM-DD>
edges:
  - {type: relates-to, to: <target-node-id>}
---

Final report from dispatched run `<run-id>` (<harness>), which ended `<state>`.
It is filed here so the run's work reaches the graph instead of vanishing into
a dead run; nothing here resolves the target.

<one of:>
The run left no resolving edge on <target>, so the item returns to the queue
carrying this report.
<or, on an out-of-scope target type:>
Whether <target> is complete was NOT verified: a `<type>` node of this type is
retired by its status rather than by a resolving edge, which is the only
signal this runner checks.

<the worker's own final report text, verbatim>
```

**Deterministic, idempotent id.** `art-dispatch-report-<stem>-<short-run-id>`,
where `<stem>` is the target node id with its type prefix stripped
(≤ 40 chars) and `<short-run-id>` is the first 8 hex chars of the run id.
The same run filing the same report twice — a retry after a transient write
failure — lands one node, not two: write with `if_exists: "skip"`. A **207**
partial-success from the batch `POST /v1/nodes` door, or a per-entry
`status: "skipped"`, both count as **landed** — only a hard transport
failure or a rejected entry means the write did not happen.

**Size discipline.** The server caps a node's `summary` at 500 chars and its
body at 8192 bytes; a filed report stays comfortably under both so a long
final report is *truncated here*, never rejected wholesale (a rejected
write is a lost report): body truncated at **7000 bytes** (byte-exact, cut
back to the last clean UTF-8 boundary, with a trailing `[report truncated —
see the run log for the full text]` notice), summary at **460 chars**, id
stem at **40 chars**.

## The run record

Every dispatched run gets one persistent local record, readable with `spor
runs --json` — `{reconciled, count, runs: [<record>]}`. `reconciled: false`
means a native-harness live-agent listing failed for this particular call,
so any shown native-background record that isn't yet terminal may be stale.
Each record spans two dimensions: **process** (how the run's process ended)
and **outcome** (what this protocol's terminal-states algorithm found, once
it has run against this record). The process dimension — `run_id`,
`harness`, `launch_mode`, the `state`/`termination_class` progression, log
and transcript paths, and so on — is documented alongside `spor runs` on
[Dispatch → runs](/reference/cli/dispatch/#runs), which also carries the
outcome dimension's full field table (`terminal_state`,
`terminal_enforced`, `resolved_by`, `resolved_edge`, `report_node_id`,
`lease_released`, `terminal_note`) — those fields map directly onto
[Terminal states](#terminal-states-the-outcome-contract) above. A record
with `terminal_state` unset (or `state` still non-terminal) has not
finished; poll or watch the record file rather than assuming absence means
failure.

Terminal records age out after `dispatch.runRetentionMs` (default 14 days,
config-cascade only, no env override) — read a record's outcome before that
window closes if it needs to outlive the run itself. The graph (the report
artifact, the resolving edge) is the durable copy; this record is an
operational journal.

## Minimal conformance checklist

A worker (and its launcher, if separate) is a conforming Spor worker when it:

- authenticates as an **agent-scoped token**, not a person's own credential,
  for every graph write it makes while doing the work
- **claims** its target node before starting, and renews before the lease's
  `expires_in_ms` horizon closes if the work runs long
- reads the compiled briefing for its target before acting non-trivially — a
  worker that skips this reinvents decisions the graph already settled
- on finishing, checks the target for a **live resolving edge** rather than
  declaring victory itself
- if no resolving edge exists, **files its final report as an artifact**
  `relates-to` the target — never silently drops the work
- **releases the lease only after the report write is confirmed** — a
  refused write leaves the lease held, never released with nothing to show
  for it
- never claims a `readiness: human` item, and never routes a mention-less
  question without stamping the session's project

Companion specs: [Reads](/reference/api/reads/) and
[Writes](/reference/api/writes/) (the REST contract this protocol is built
from), [Nodes](/reference/graph-model/nodes/) and
[Edges](/reference/graph-model/edges/) (the format `resolves`/`answers`
edges and report artifacts follow), and [Leases](/reference/api/leases/)
(the full claim/renew/extend/release/reserve family).
