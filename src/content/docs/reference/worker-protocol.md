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
principal, not a person. Create one (self-serve, no admin needed):

```
POST /v1/agents {label}                       →  agent-<slug>, owned-by <you>
POST /v1/agents/{id}/token {session?}          →  a bearer token scoped to it
```

Every write under an agent-scoped token is stamped `authored_by_agent:
<agent-id>` and `session: <id>`, with `authored_via: dispatch`; `author:`
stays the agent's owning person, so the node reads "agent on behalf of
person." This is the token a worker process should hold — never a person's
own account-scoped token or connector session, which would attribute the
work to the human instead of the agent that did it.

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

On top of that floor, `spor work`'s pickup is configurable via the
acceptance policy (`--accept`, the `work.accept` config key, or
`SPOR_WORK_ACCEPT`). `ready` — the default — is explicit consent: only
items whose derived readiness is `agent` (a person's `spor ready <id>`
stamp, or an `assigned -> agent` routing) are dispatched; an `untriaged`
item is skipped with a visible reason on the worker's stdout and in
`spor work --status`. `open` opts back into the looser pickup: everything
except `readiness: human` — that floor is not part of the knob. An unknown
value refuses to start the worker, and `spor work --print` shows the
effective policy.

**The page widens rather than starving.** Selection reads a fixed-size
ranked page, and the policy above filters what comes back — so a page
filled entirely by items this worker may not take would hide an eligible
one ranked below it on every poll, forever. When nothing on the page is
dispatchable by this worker — un-consented, out of scope, already in
flight here, or cooling off after a refusal — the read widens (doubling,
up to a server-enforced ceiling) until something is dispatchable or the
queue is exhausted. A pass that finds a candidate on the first page pays
nothing extra, and the width a pass needed carries over to the next poll,
so a worker starved behind a page of items it may not take still pays only
one queue read per poll rather than re-walking the ladder every time.

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

## The integration step: a code-enforced merge queue after gates

`spor work --factory <id>` can declare an **`integration:`** block on the
factory definition — the pipeline's LAST stage, run only after every
declared gate has passed. It is opt-in, exactly like the gate list itself: a
factory that declares no `integration:` block resolves work exactly as
described above, with no adoption cliff. Where it applies, a `resolved`
verdict in the [terminal states](#terminal-states-the-outcome-contract)
sense above is only reachable once this stage lands the change (or, under
`propose` mode, is deferred to a later pass — see below).

```json
{
  "integration": {
    "target_ref": "main",
    "mode": "local",
    "command": "npm test",
    "strategy": "merge",
    "serialize": "repo"
  }
}
```

| Field | Means |
| --- | --- |
| `target_ref` | what "landed" means; defaults to the factory's own `trusted_ref` |
| `mode` | `local` CAS's a local ref with `git update-ref`; `push` pushes to a remote, whose own non-fast-forward rejection *is* the compare-and-swap; `propose` opens a pull request instead of mutating `target_ref` at all — see [Propose mode](#propose-mode-pr-landing-for-review-policies) below |
| `command` | the FULL suite, run on the merged candidate tree — never a fast tier deferred to a service after landing |
| `strategy` | `merge` \| `squash` \| `rebase` — how the candidate tree is built |
| `serialize` | the lease's scope; `repo` is the only value today |
| `reruns` | default `0`, at most `3` — the same bounded same-tree rerun a command gate has: the candidate suite reruns on the one candidate worktree (never rebuilt) before a failure becomes a fix cycle |

**The candidate build.** A throwaway worktree at `merge(target_ref,
branch)` per the declared strategy — `merge` lands the branch onto the
target, `rebase` replays the branch's own commits onto it, `squash` folds
the branch into one commit on top of it. A merge conflict is a **fix-cycle
event, not a terminal error** — fed back to the same implementer through
the same cycle-cap-then-escalate machinery a failing gate uses.

**Protected paths are forced, again**, under the same guarantee and matcher
a command gate's candidate tree gets: every declared `protected_paths` glob
is restored to the trusted ref's own copy before the suite runs. That
restore only rewrites the candidate worktree's working directory (it
creates no commit), so when the restore changes anything the stage
re-commits the restored tree and lands *that* sha instead of the
pre-restoration one — otherwise a tampered protected-path edit could ship
behind a suite that only ever ran against the restored tree.

**The candidate suite runs full, on the merged tree, every landing** — a
failure feeds into the same fix-cycle machinery a conflict does.

**Landing is compare-and-swap**, and losing the race is nobody's mistake.
Local mode's `git update-ref target_ref new_sha old_sha` refuses if the ref
moved since the candidate was built (and brings a checkout with
`target_ref` already checked out up to date for the landed paths, where its
index and working copy were otherwise untouched); push mode's rejection of
a non-fast-forward push is the same guarantee over a remote ref, and push
mode fetches the target before every candidate build so a rebuild after a
lost race is always against the live tip. Either way, a **lost race
rebuilds the candidate against the ref's new tip and reruns** —
automatically, bounded by a small retry ceiling, and *never* charged
against the fix-cycle cap: the implementer did nothing wrong, another
landing simply won first. The `serialize: repo` lease (a server-held claim
in remote mode, a machine-local lockfile with no server) makes this race
*rare*; the CAS is what makes it *harmless* regardless — every failure
acquiring the lease is fail-open, logging a note and proceeding without
one.

**Every landing or failure is a graph fact**, `art-merge-…` — the
integration stage's twin of a gate's `art-gate-…` fact: the same idempotent
id scheme, the same `relates-to` (never `resolves`) edge onto the work
item. A failure that exhausts its fix cycles **demotes the item exactly as
a failed gate does**: an escalation is filed that `blocks` the work item,
and the item's completion status is rolled back if it claimed one — the
run's resolver already declared every gate passed, so the only thing an
integration failure disputes is whether the change ever reached the target
ref. The same `gate_escalation_failed` marker and `spor work --regate
<run-id>` door back apply here exactly as they do to a gate refusal.

**Cleanup** runs on a landing or a proposal. The candidate worktree is
always removed, win or lose (it is throwaway by construction); the
implementer's own dispatch worktree and branch are removed once the work
has either landed or been proposed — a `propose`-mode PR is already durable
on the remote once opened, so there is nothing left for the dispatch
worktree to hold. Only an outright failure (a conflict or a suite that
never resolves, a PR that never opens) leaves the dispatch worktree
standing.

### Propose mode: PR-landing for review policies

`mode: propose` runs the identical candidate build, protected-path
restore, and full suite every other mode runs — the point of running it
pre-PR is that the PR is known-green the moment it opens. Only the landing
step differs: instead of a CAS mutating `target_ref`, it pushes the
implementer's **own branch** (`tree.head`, unmerged — never the throwaway
candidate commit, which only ever proved merging would be green) and opens
a PR against `target_ref` through the `gh` CLI, the v1 backend. `gh` is a
declared capability, checked through the same [machine-profile
satisfiability](/reference/dispatch/#capabilities-what-this-machine-can-actually-run)
layer a profile's harness/MCP/skills/plugins already go through: loading a
factory that declares `propose` warns loudly, once, at
the same load-time check an unreadable factory already gets, but does not
kill the whole worker — a box that can never land a proposal idles,
visibly (in `spor work --status`), skipping every candidate rather than
crash-looping, leaving the item for a capable box. No lease is ever
established on a box that can't finish the job. A re-run (a fix cycle, or a
resumed pipeline) reuses whatever PR is already open for the branch rather
than erroring on a duplicate.

**Opening the PR parks the item — it does not resolve it, and it frees the
work-loop slot immediately.** This is deliberately not the shape of a
`human` gate, which polls a graph approval in-process for up to a day
(`approval_timeout_ms`), holding a concurrency slot the whole time — fine
for an approval a person answers within a shift, wrong for a PR review that
can legitimately take days. Parking instead reuses only the graph-state
half of a failed gate's demotion: a tracking item is filed carrying a
`blocks` edge onto the work item, and the work item's own completion status
is rolled back if it claimed one — never an in-process poll, and nothing is
marked for a person at this point. The pipeline returns an additional
settled gate state, `parked` (alongside `passed`/`failed`/`blocked`), and
the work-loop slot frees on that return exactly like any other settled
verdict.

A `human` gate and `propose` mode never double-file an approval: a `human`
gate is a gate — it runs and is judged *before* integration ever starts (an
internal "should we even try to land this" call), through a wholly
different door than propose mode's own tracking item. A factory can
declare both — the `human` gate judges the change itself pre-integration,
and `propose` mode's PR is the org's independent, external review-and-merge
gate on the same change afterward. Neither one knows the other exists.

**Resolving a parked item is a separate later pass, never a resume of the
run that parked it.** Because a parked run's own pipeline is already
settled, it is never re-entered to ask "did the PR land yet" — instead
`spor work`'s loop periodically checks every parked run's PR via `gh pr
view`:

- **Still open** — a no-op; nothing is written until the next pass.
- **Merged onto the expected `target_ref`** — writes a second
  `art-merge-…` fact for the same run (a distinct id segment keeps it from
  colliding with the first), carrying a `resolves` edge onto the tracking
  item — the one point in this pipeline where an integration fact retires
  something rather than merely recording it — then restores the work
  item's own completion status and closes the tracking item.
- **Merged onto a different base than expected** — a `base-mismatch`
  verdict: records a fact (the PR number, the actual base, and the
  expected `target_ref`) but resolves and restores nothing, leaving the
  tracking item parked for a person to reconcile — the PR technically
  landed, but not where the pipeline verified it against.
- **Closed without merging** — writes a fact recording it, but restores
  nothing and leaves the tracking item open: the PR was rejected on
  GitHub's own review surface, and — same as a `human` gate's own rejected
  approval — a person decides what happens next, not the worker.

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
Each record spans two independent dimensions: **process** (how the run's
process ended — always present) and **outcome** (what this protocol's
terminal-states algorithm found, once it has run against this record).
Consumers should treat unlisted or absent fields as `null`/absent, not as a
schema violation — new fields may be added additively.

**Process dimension** (every record):

| Field | Type | Meaning |
| --- | --- | --- |
| `run_id` | string (uuid) | this run's unique id |
| `node_id` | string \| null | the target node, or `null` for a free-text dispatch |
| `name` | string \| null | the launch name (defaults to the node id, or the first few words of free text) |
| `harness` | string | adapter id: `claude-code`, `codex`, `opencode`, `copilot`, … |
| `launch_mode` | string | `"native-background"` (detaches into the harness's own daemon) or `"supervised-jsonl"` (runs under a supervisor Spor owns) |
| `state` | string | `"launching"` → `"running"` → one of the terminal process states: `"done"`, `"failed"`, `"failed_launch"`, `"vanished"` |
| `cwd` | string | the run's working directory |
| `model` | string \| null | native-background records only — the model override this launch resolved, `null` when none did. A supervised record carries no `model` key at all, since its model is fixed into the harness argv at launch |
| `created_at` / `finished_at` | ISO 8601 | when the record was opened / went terminal |
| `started_at` | ISO 8601 | supervised runs only — when the child process actually started |
| `launched_at` | ISO 8601 | native runs only — when the launcher observed the harness hand off to its background daemon |
| `exit_code` / `signal` | int \| null / string \| null | supervised runs only |
| `termination_class` | string | a broad bucket: `"completed"`, `"environment"` (credit/rate/auth exhaustion — re-dispatchable, not a real failure), `"launch"`, `"failed"`, `"idle"` (a run that stopped writing anything and was stopped for it), or `"unknown"` — an open vocabulary; do not exhaustively switch on it |
| `termination_reason` | string | a human-readable one-line explanation |
| `session_id` | string \| null | the harness's own session/thread id, possibly bound after launch (see [Agent identity and attribution](#agent-identity-and-attribution)) |
| `transcript_path` | string | native runs only, when a transcript was found |
| `log_path` / `report_path` | string | supervised runs only — the raw log, and where the harness's own final-message text landed, if any |

**The two launch modes carry different fields, and that asymmetry is part
of the schema, not an omission to read around.** A `native-background`
record carries `launched_at` (never `started_at`), plus `model`; a
`supervised-jsonl` record carries `started_at`, `exit_code`, `signal`,
`log_path`, and `report_path` — and no `model` key at all.

**Outcome dimension** (present once the terminal-states algorithm above has
run against this record — absent while `state` is still non-terminal):
`terminal_state`, `terminal_enforced`, `resolved_by`, `resolved_edge`,
`report_node_id`, `lease_released`, and `terminal_note` — the full field
table is documented alongside `spor runs` on [Dispatch →
runs](/reference/cli/dispatch/#runs), and those fields map directly onto
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
edges and report artifacts follow), [Leases](/reference/api/leases/)
(the full claim/renew/extend/release/reserve family), and
[Dispatch → capabilities](/reference/dispatch/#capabilities-what-this-machine-can-actually-run)
(the satisfiability check `propose` mode's `gh` requirement is checked
through).
