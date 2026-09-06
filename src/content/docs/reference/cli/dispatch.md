---
title: Dispatch
description: Launch background agents against queue items, with agent identities, repo maps, and capability matching.
sidebar:
  order: 8
---

Dispatch turns a queue item into a running background agent: `dispatch`
compiles a briefing and launches one session, `work` loops `dispatch` over
the queue continuously, `agent` manages the identity a session runs as,
`repos` maps repo slugs to directories on this machine, and `capabilities`
declares what this machine can run.

### agent

```
spor agent create <label> [--owner <id>] [--pubkey <fp>]
spor agent list
spor agent use <agent-id> [--clear]
spor agent token <agent-id> [--expires <Nd|date>] [--label <l>]
spor agent token <agent-id> list
spor agent token <agent-id> revoke <prefix>
```

**Mode:** dual (`token` is remote-only)

Create and manage agents — first-class `type: agent` nodes owned by a
person. A dispatched session runs as its agent, so its writes read "agent on
behalf of person" rather than person-direct. One durable agent per machine
or install, reused across dispatches.

| Subcommand | What it does |
| --- | --- |
| `agent create <label>` | create the agent and its `owned-by` edge. Without `--owner` the agent is owned by you (self-serve); `--owner <person-id>` creates it for another person (admin). In local mode the owner defaults to the sole person node. `--pubkey` records a public-key fingerprint (forward-compat, unenforced). |
| `agent list` | list agents and their owners |
| `agent use <agent-id>` | make it this machine's default dispatch identity — a local config write (`dispatch.agent`), not a graph write. `--clear` unsets it — a real remote dispatch then hard-fails unless `--allow-person-token` is set (below). |
| `agent token <agent-id>` | mint a long-lived standing PAT for the agent — the `SPOR_TOKEN` a headless agent runs under; shown once. `--expires` shortens the lifetime (default and max 1 year), `--label` tags it. `list` and `revoke <prefix>` manage them. Remote-only, owner-gated. |

```sh
spor agent create ines-laptop
spor agent use agent-ines-laptop
```

### dispatch

```
spor dispatch "<task>" | <node-id> [options]
```

**Mode:** dual · **Alias:** `bg`

Compile a briefing for a task and launch a Claude Code background agent in
the right repo. The target is free text, a node id, `--node <id>`,
`--from-queue` (the top-ranked item not already in flight on this machine),
or `--backfill` (the unattended init + enable + backfill primitive). The
target directory comes from the slug map ([`spor repos`](#repos)),
overridable with `--dir`.

In remote mode a node dispatch auto-claims the task, establishing the
heartbeat lease at dispatch time, so concurrent dispatch of the same node is
refused (the holder is named); `--no-claim` opts out. A node dispatch is
also refused when an agent for that node is already in flight on this
machine, or when the target is already resolved (a terminal status, or
retired by an inbound `resolves`/`answers` edge) — `--force` overrides both.

A node dispatch also checks its derived
[agent-readiness](/reference/graph-model/node-types/#agent-readiness) before
launch, refusing outright on `requires: human` (`cannot dispatch <id>: this
item requires a human — <reasons>.`, no `--force` override) and warning on a
broader `readiness: human`. See [Dispatch, capabilities, and
profiles](/reference/dispatch/#agent-readiness-before-launch) for the full
behavior, including the local-vs-remote difference in what the warn case
checks.

`--worktree` runs the agent in its own git worktree off the repo (branch
named for the node id or sanitized task), so parallel dispatches never race
the shared tree. Make it a repo default with the `dispatch.worktree` config
key, in the target repo's committable `.spor.json` or your machine-local
config; `dispatch.worktreeSetup` names a hook that preps each worktree,
running with the worktree as cwd and `SPOR_WORKTREE`, `SPOR_MAIN_CHECKOUT`,
and `SPOR_DISPATCH_SLUG`/`SPOR_DISPATCH_NODE` in the environment.
`--no-worktree` opts a single run out.

When this box can't satisfy the resolved profile, `--auto-route`
(`dispatch.autoRoute`, `SPOR_AUTO_ROUTE`; default off) hands a **node**
dispatch to the freshest of the caller's own fleet hosts that does satisfy
it, writing `assigned -> <host agent>` with the same profile pinned — never
a substitution, and still escalating to the owner when no host satisfies the
profile. `dispatch.autoRouteMaxAge` (`SPOR_AUTO_ROUTE_MAX_AGE`, default
`24h`) bounds a target's staleness; `--no-auto-route` opts a single run out.
See [Dispatch, capabilities, and profiles → Auto-route](/reference/dispatch/#auto-route-closing-the-loop-without-a-human)
for the full behavior.

Two different agent axes — do not confuse them: `--as <agent-id>` picks the
Spor agent identity the dispatch runs as (attribution; remote-only; defaults
to `dispatch.agent`), while `--agent <A>` is the unrelated `claude --agent`
passthrough that picks the harness agent definition the session runs.

A real (non-`--print`) remote dispatch **hard-fails** when no agent identity
resolves — no `dispatch.agent` configured and no `--as` given — or when
minting an agent-scoped session token fails, naming `spor agent use
<agent-id>` as the fix. This applies equally to `spor work`'s autonomous
loop, which shares the same code path. It replaces the old behavior of
silently falling back to a person-scoped token, which misattributed a
dispatched agent's writes to the human operator. `--allow-person-token`
(the standing `dispatch.allowPersonToken` config key, or the
`SPOR_ALLOW_PERSON_TOKEN` env var) restores that fail-soft fallback, with a
loud warning on every launch it permits — the escape hatch for solo/local
use where minting a machine identity isn't worth the setup. Local mode is
unaffected (there is no CA to mint an agent token against).

| Flag | Effect |
| --- | --- |
| `--dir <path>` | launch directory, overriding the slug map |
| `--node <id>`, `--slug <slug>` | dispatch a specific node; target a repo slug |
| `--as <agent-id>` | Spor identity to run as (remote-only) |
| `--model <M>`, `--permission-mode <P>`, `--agent <A>`, `--name <N>` | passthroughs to `claude`; `--model`/`--name` are harness-neutral, `--permission-mode`/`--agent` are Claude Code-only |
| `--profile <profile-id>` | profile to run under, checked against this machine's capabilities |
| `--sandbox <S>`, `--approval-policy <P>` | Codex-only passthroughs; mutually exclusive with `--permission-mode`/`--agent` — the wrong one for the resolved harness is a hard error, except `--permission-mode bypassPermissions` against Codex, which translates to `--sandbox danger-full-access --approval-policy never` with a warning instead of erroring |
| `--read-only` | enforce the harness's own read-only posture (Codex's `--sandbox read-only`, Claude Code's plan permission mode) instead of whatever `--sandbox`/`--permission-mode` was passed, overriding it with a warning; a harness with no declared read-only posture refuses the launch rather than running write-capable behind the flag. This is what [an agent-review gate](/reference/factory/#agent-review-gates--a-verdict-that-is-read-not-asserted) dispatches its reviewer under, but it is a plain dispatch flag, usable on any `spor dispatch` |
| `--template <F>` | prompt template file with `{{brief}}`/`{{task}}`/`{{node}}`/`{{title}}`/`{{slug}}`/`{{dir}}`/`{{default}}` placeholders |
| `--full`, `--no-brief` | full briefing instead of the digest; raw prompt with no briefing block |
| `--no-claim`, `--force` | skip the auto-claim; dispatch despite an in-flight agent or resolved node |
| `--auto-route`, `--no-auto-route` | hand an unsatisfiable node dispatch to a satisfying fleet host (`assigned -> host agent`, same profile pinned); force-disable a standing `dispatch.autoRoute` default for this run |
| `--bg` | Claude Code only — launch the native background session (`claude --bg`) instead of the default supervised launch; trades an enforced [terminal-state](/reference/worker-protocol/#terminal-states-the-outcome-contract) outcome for the attachable, interactive form (`claude attach`). Also settable as `dispatch.claudeLaunchMode: native-background`. `spor work` never uses it |
| `--allow-person-token` | fall back to a person-scoped token when no agent is configured or minting fails (default: hard-fail; also `dispatch.allowPersonToken` / `SPOR_ALLOW_PERSON_TOKEN`) |
| `--from-queue`, `--backfill` | top-ranked queue item; unattended repo backfill |
| `--worktree`, `--no-worktree` | per-run worktree isolation override |
| `--print` (alias `--dry-run`) | print the prompt, launch nothing |

```sh
spor dispatch task-tidefall-retry-emails --worktree
spor dispatch --from-queue --print
```

### work

```
spor work [options]
```

**Mode:** dual — each dispatch it makes follows local/remote exactly like
`spor dispatch`; `--status` and `--regate` read only the local run journal.

Works the queue continuously instead of one item at a time: it polls,
dispatches the items this machine may take under their routed profile, waits
for each run's [terminal state](/reference/worker-protocol/#terminal-states-the-outcome-contract),
and goes around again. It is pull, not push — nothing schedules a worker,
it takes work, and a dead worker simply drops its lease at expiry with no
sweep needed. Every launch goes through the same code path as `spor dispatch
--node <id>` — the same duplicate guard, auto-claim, worktree isolation, and
[agent-readiness check](/reference/dispatch/#agent-readiness-before-launch) —
minus anything `readiness: human` or already in flight here. A run that is
refused, or ends without resolving its target, is remembered with the reason
and retried after `--retry-after` rather than reattempted on the next poll.

| Flag | Effect |
| --- | --- |
| `--project <slug>` | scope the queue to one project (`work.project`) |
| `--concurrency <N>` | runs in flight at once (`work.concurrency`, default 1) |
| `--accept <ready\|open>` | acceptance policy — see [Worker protocol → The pool and the claim](/reference/worker-protocol/#the-pool-and-the-claim) (`work.accept` / `SPOR_WORK_ACCEPT`, default `ready`) |
| `--once` | poll and dispatch once, then exit |
| `--max <N>` | stop after dispatching N runs |
| `--retry-after <dur>` | cooldown before re-offering a refused or unresolved item (`work.retryAfterMs`) |
| `--run-idle <dur>` | stop a run whose log and transcript have both gone silent for this long, freeing its slot (default 45 minutes; `0` disables the ceiling) |
| `--run-max <dur>` | hard backstop that frees a slot regardless of activity (default 24 hours) |
| `--factory <id>` | enforce a factory's gate pipeline between claim and resolve (`work.factory`) |
| `--print` | show scope, pacing, and candidates; launch nothing |
| `--status` | every worker on this box: slots, outcomes, what is being skipped and why |
| `--regate <run-id> --factory <id>` | re-judge one refused run's gates after fixing what refused it, without re-dispatching the work |

```sh
spor work --project tidefall --concurrency 2
spor work --once --print
spor work --status --json
```

`--run-idle` measures silence, not a wedged agent specifically: a single
tool call that legitimately runs longer than the ceiling — a full test
matrix, a slow build — looks identical to a stuck run and is stopped
mid-work all the same, so raise it (or set it to `0`) for a lane whose steps
genuinely take that long. A run with no observable channel at all (a
native-background launch whose session was never bound) is never judged
idle; it falls through to `--run-max` instead, which frees the slot without
making any claim about the run. Being stopped for idleness is a process
fact, not an outcome — an agent that had already written its resolver
before going quiet still reads `resolved`.

`--status`'s `gating:` slots also surface a controller-completion [execution
hold](/reference/factory/#controller-completion-the-resolving-edge-written-at-a-declared-boundary)
when one is active — the holding execution, the completion boundary it is
pinned to, when it was claimed, and the same live/STALE worker reading
`spor get`'s HELD note uses:

```
  gating:   task-tidefall-retry-emails  run a1b2c3d4  since 2026-09-06T03:10:00Z
            execution: exec-4d5c6b7a9e1f2a3b (boundary 'integration'), held since 2026-09-06T03:10:12Z — run a1b2c3d4, its worker is live
```

Read off the gate run record's pinned `impl_claim`, never restamped on the
worker's own status file; absent under `completion.by: agent` or on a
legacy run. `--status --json` carries the identical data as a `hold` object
on the gating entry.

### runs

```
spor runs [<run-id>] [options]
```

**Mode:** local

The durable record of every background agent *this machine* has dispatched —
how each run ended, and where to look. Don't confuse this with [`run
status`](/reference/cli/writing-to-the-graph/#run), which inspects a
server-side workflow-engine run; `runs` is the local dispatch launch record.

A native-background dispatch (Claude Code launched with `--bg`) detaches
into the harness daemon, so the launcher never sees the child exit — without
this record a finished run and a dead one are indistinguishable afterwards.
Every supervised harness — Claude Code by default, Codex, OpenCode, GitHub
Copilot CLI — instead runs under a supervisor Spor itself owns, streaming
progress into a private log and capturing the run's final message to a
report file; see [Choosing a
harness](/reference/dispatch/#choosing-a-harness) for what it prints at
launch. **Reading reconciles first**: every run the harness no longer
reports live is resolved against its own evidence — a native dispatch's
transcript, a supervised one's own log — and stamped with a terminal state,
a classification, a reason, and a diagnostic pointer — so a run's state can
advance simply from running `spor runs`. `--json`'s top-level `reconciled`
field reports whether that pass fully succeeded for this call: `false`
means a native-harness live-agent listing failed, so any shown
native-background record that isn't yet terminal may be stale.

A run starts at `launching`; the harness never starting closes it straight to
`failed_launch`, otherwise it advances to `running` and from there to one of
the other three terminal states:

| State | Meaning |
| --- | --- |
| `done` | the session ended its turn cleanly |
| `failed` | it ended for a recognized reason (see the classification) |
| `vanished` | it stopped mid-turn with no end-of-turn marker, or left nothing attributable to it |
| `failed_launch` | the harness never started |

Each terminal run also carries a classification that keeps causes from being
conflated: `environment` (provider credit exhaustion, usage limits, rate
limits, rejected auth — re-dispatch once that clears), `launch`, `failed`,
`completed`, `idle` (a `spor work` run whose log and transcript both stopped
moving and was stopped for it — see [`work`](#work)), or `unknown`. Evidence
is always the run's own — a transcript is matched by the session the run
bound, never by the directory it ran in, since several dispatches can share
one checkout. A run still inside its first minute, or one whose harness
couldn't be queried at all, is left alone rather than declared dead.

**Process and outcome are two different dimensions of the same record.**
Everything above — `state`, `termination_class`, and friends — is the
*process* dimension: how the harness's own process ended. Once the
[worker protocol](/reference/worker-protocol/)'s terminal-states algorithm
has run against a finished record, it also carries an *outcome* dimension:
what the run actually did to the **graph**, which a process ending cleanly
does not by itself guarantee.

| Field | Meaning |
| --- | --- |
| `terminal_state` | `"resolved"` \| `"reported"` \| `"declined"` \| `"failed"` — see [Terminal states](/reference/worker-protocol/#terminal-states-the-outcome-contract) |
| `terminal_enforced` | whether this was a *verified* verdict (re-read against a reachable graph) or a best-effort classification — gate on this before trusting `terminal_state` as ground truth |
| `resolved_by` | present only when `terminal_state === "resolved"` — the resolver node's id |
| `resolved_edge` | present only when resolved — `"resolves"` or `"answers"` |
| `report_node_id` | present only when a report was actually filed — its presence always implies `terminal_state === "reported"`, but an unenforced `reported` record may have none |
| `declined_reason` | present only when `terminal_state === "declined"` — the reason off the report's `DECLINED:` line |
| `finding_node_id` | present only when a decline's finding was actually filed — its presence always implies `terminal_state === "declined"` |
| `readiness_cleared` | declined only — whether the target's `readiness: agent` stamp was cleared |
| `lease_released` | optional — whether a release attempt succeeded; omitted (not `false`) when no lease was this run's to release at all |
| `terminal_note` | a human-readable explanation of the outcome, always present once this dimension exists |

A record with `terminal_state` unset (or `state` still non-terminal) has not
finished; poll or watch the record file rather than assuming absence means
failure.

**A run dispatched under a factory's `implementation:`/`completion:` blocks**
also prints its own stage lines — absent for a legacy run or a factory
declaring neither block:

```
stage:      candidate
candidate:  cand-9f8e7d6c5b4a3210  tree 1a2b3c4d5e6f  commit 7f6e5d4c3b2a on task-tidefall-retry-emails  bundle
            re-pinned 2x — cand-aaaa1111bbbb2222 -> cand-cccc3333dddd4444 -> (tip)
completion: by controller at 'integration' — owed (write); execution exec-4d5c6b7a9e1f2a3b
            gates passed, integration running
```

`stage:` is `impl_state`, the settled-or-not verdict on the implementation
stage itself; `candidate:` is the tip `impl_candidate` (with the re-pin
count when the chain is longer than one); `completion:` is the pinned
boundary, what the controller has written so far (`owed (<debt>)`,
`written`, `withdrawn`, or `consumed`), and the holding execution id. See
[Factory → The candidate](/reference/factory/#the-candidate-what-a-pipeline-is-judging-pinned)
and [→ Controller
completion](/reference/factory/#controller-completion-the-resolving-edge-written-at-a-declared-boundary)
for the full field reference.

`<run-id>` filters to one run by full id or short prefix; `--node <id>`
filters to every run dispatched for a node; `--limit <N>` bounds how many are
shown (default 20); `--json` prints the raw run records instead of the
one-line-plus-detail text format. Terminal records age out after
`dispatch.runRetentionMs` (default 14 days).

| Flag | Effect |
| --- | --- |
| `--node <id>` | only runs dispatched for this node id |
| `--limit <N>` | how many runs to show (default 20) |
| `--json` | machine-readable JSON (the raw run records) |

```sh
spor runs
spor runs --node issue-x
spor runs --json     # {reconciled, count, runs} — a supervised run's final
                      # message is at .runs[0].report_path
```

### repos

```
spor repos [list | add <slug> <path> | rm <slug> | tags | tag <slug> [tag...] | untag <slug> [tag...]]
```

**Mode:** dual (the slug map is local; tags write the graph)

Two repo registers in one place.

The machine-local slug-to-directory map dispatch uses to find a repo. It
self-registers as you open sessions and lives in your user config:
`repos` lists it, `repos add <slug> <path>` maps a slug, `repos rm <slug>`
forgets one.

Repo-identity tags on the `repo-<slug>` graph node — the match key for a
norm's tag-scoped ride-along. An untagged repo excludes every tag-scoped
norm, so tagging is the deliberate opt-in that turns them on. `repos tags`
lists every repo node with its slugs and tags; `repos tag <slug> <tag...>`
sets (replaces) a repo's tags, and with no tags shows the current ones plus
auto-suggestions from disk; `repos untag <slug> [tag...]` removes tags (no
tags clears all).

```sh
spor repos add billing ~/code/billing
spor repos tag billing python backend
```

### capabilities

```
spor capabilities [list [--json] | show <agent-id> | probe | publish | hosts <profile-id> | set <axis> <v...> | add|rm <axis> <v...> | allow-mcp <m...> | deny|undeny <profile-id...> | clear]
```

**Mode:** dual (`show`, `publish`, `hosts` are remote) · **Aliases:** `caps`, `profiles`

Show or edit the per-machine capability map dispatch matches against an
agent's profile. Harnesses, plugins, and skills self-probe each session;
declare what a probe cannot decide (reachable MCP servers, deny flags).
Declared augments probed; deny overrides both. Stored in the machine-local
config, never a committed `.spor.json`. The axes are `harnesses`,
`reachable_mcp`, `skills`, and `plugins`.

| Subcommand | What it does |
| --- | --- |
| `capabilities` | show this machine's effective capabilities |
| `probe` | re-probe harnesses, plugins, and skills now |
| `set <axis> <v...>` / `add` / `rm` | declare or adjust an axis |
| `allow-mcp <name...>` | declare a reachable MCP server |
| `deny <profile-id...>` / `undeny` | policy opt-out of a profile |
| `clear` | reset declarations and the probe cache |
| `publish` | push this machine's capabilities to the team fleet scheduler, keyed on `dispatch.agent` (run `spor agent use` once first). Session-start auto-publishes in remote mode; `SPOR_CAPABILITIES_PUBLISH=0` disables that. |
| `show <agent-id>` | read what a specific machine advertised (readable by the agent's owner, the agent itself, or an admin); pass `me` for this machine's own published record |
| `hosts <profile-id>` | which fleet machines satisfy a profile, and which cannot, with reasons. Scope with `--owner me\|person-x`; demote stale publishes with `--max-age 30m\|12h\|7d`. `spor dispatch` prints these automatically when this machine cannot satisfy a profile. |

```sh
spor capabilities allow-mcp spor
spor capabilities hosts profile-docs-writer
```
