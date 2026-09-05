---
title: "Factory: gates and the merge queue"
description: The declarative gate pipeline spor work --factory enforces between a run's resolve and the item counting as done — command, agent-review, and human gates, the merge-queue integration step, and the rescue lane.
---

**Use this when** you are standing up or reading a factory definition —
what must be true before a `spor work` run's claim of completion counts —
or debugging why a run escalated, got demoted, or is stuck gating.

**You do not need this if** you only run `spor work`/`spor dispatch` with no
factory declared; see [Dispatch, capabilities, and
profiles](/reference/dispatch/) instead. If you are implementing your own
worker and need the exact claim/brief/work/report/resolve wire contract a
factory sits on top of, that is [Worker protocol](/reference/worker-protocol/).

**After reading this, you should be able to** read a factory's JSON payload
field by field, know which of the three gate kinds applies to a check you
want enforced, and follow a refused run from escalation through to a
re-gate or a rescue.

Everything here is enforced in code by the runner, never handed to an
orchestrator agent as prose instructions — a prompt that asks an agent to
"run the review and act on it" is not a gate, it is a suggestion with a
plausible-looking transcript. It is entirely **opt-in**: `spor work` with no
factory declared resolves work exactly as [Worker protocol](/reference/worker-protocol/)
describes, with no adoption cliff in either direction. Point it at one —
`spor work --factory <id>` (or the `work.factory` config key, see
[Dispatch → work](/reference/cli/dispatch/#work)) — and the declared gates
run between a run ending and the item counting as done.

## The factory definition is graph data

A `type: factory` node (candidate schema `schema-factory`, adopted with
`spor schema adopt schema-factory`) carries a fenced JSON payload:

```json
{
  "factory": "spor-default",
  "trusted_ref": "main",
  "repos": ["spor"],
  "protected_paths": ["test/**", "conformance/**"],
  "test_lane_profile": "profile-test-writer",
  "risk_classes": { "touches:auth": ["lib/auth.js", "**/auth/**"] },
  "gates": [
    { "id": "acceptance", "kind": "command", "command": "npm test", "timeout_ms": 900000 },
    { "ref": "gate-adversarial-review", "cycles": 2 },
    { "id": "security-approval", "kind": "human", "risk": ["touches:auth"] }
  ]
}
```

| Field | Means |
| --- | --- |
| `trusted_ref` | the ref command gates diff against and the candidate suite is judged from — defaults for `integration.target_ref` too |
| `repos` | the repos this factory may judge — **not** the same thing as the worker's `--project` scope; see below |
| `protected_paths` | globs a branch must not touch (test suites, conformance goldens); routed to `test_lane_profile` when it does |
| `test_lane_profile` | the profile a protected-path change is routed to as its own queue item |
| `risk_classes` | named path predicates a command/agent-review/human gate can arm on with `risk: [...]` |
| `gates` | an ordered list, each inline or a reference (`ref: <gate-id>`) to a shareable `type: gate` node (`schema-gate`) |

**`repos` bounds what the pipeline judges, and the worker's `--project` is
not the same axis.** A queue scope token resolves *up* to a repo's home
project and unions its siblings — the right read for a human, wrong for a
gate authored against one checkout:

- an item whose own repo stamp is not in `repos` is **skipped**, visibly, on
  stdout and in `--status` — never silently gated against the wrong suite;
- with no `repos` declared, the factory node's own `repo:` stamp is the
  scope; a factory with neither is unscoped, exactly as before this field
  existed;
- `"repos": []` is a fatal error, not "judge everything";
- historical repo aliases (`slugs:`) are matched raw — name the alias in
  `repos` to admit it;
- with a single declared repo and no explicit `--project`, the worker's
  queue scope defaults to that repo's slug.

**`gates` is ordered**, and the runner treats an inline gate and a `ref:`
reference identically — a reference is unwrapped into exactly the object an
inline gate would be, keys beside the `ref` overriding it. Only the
provenance on the recorded outcome differs. Writing a factory by hand is not
the only door: the reference client ships a factory-builder skill
(`/spor:factory`) that compiles a definition from an operator interview plus
a read of the repo, the graph, and the machine's capabilities, and maintains
it afterwards from the `art-gate-*` facts a factory's own gates leave behind
(see [Every gate outcome is a graph fact](#every-gate-outcome-is-a-graph-fact)) —
it authors data only, and never enforces anything itself.

**Validation is strict**, because a mistyped factory must never produce a
worker that silently accepts everything. A definition that cannot be read,
or does not validate, refuses to start the worker (exit 1, naming every
problem): an unknown gate kind, a command gate with no `command`, an
agent-review gate with no `profile`, a reference the graph cannot supply, a
duplicate gate id, `protected_paths` with no `test_lane_profile` to route
to, a human gate naming an undeclared risk class, and a `repos` list naming
no repo are all fatal. **`status` is enforced too** — the factory node and
every `type: gate` node it references must be `status: active` (or carry no
status at all) or the worker refuses to start, naming the offending node.
Retiring a factory or a shared gate by flipping its status to `retired` (or
leaving it `proposed`) is therefore enough to decommission it on its own.

## What gets gated

Only two run outcomes are gated at all:

- **`resolved`** — the run wrote a resolver and [Worker protocol's terminal
  states](/reference/worker-protocol/#terminal-states-the-outcome-contract)
  verified the edge on the graph. That verified claim is exactly what the
  gates test.
- **an unenforced `reported`** — a run whose claim nobody could check
  (local-mode dispatch, an unreachable server, a native-background launch).
  The gates are then the only check there is, so skipping them would make
  gating quietly mode-dependent.

An enforced `reported` run self-declares *not* done and is never gated; a
`failed` run produced nothing to gate; a `declined` run (§ Worker protocol)
is never gated either — it declared the item wrong, and its route is
triage, not the pipeline.

A gated run whose diff is **empty** may still be a correct outcome — the
item's real work was scoping, not code. That is not a fourth gated outcome
but a route through the pipeline, taken only when the run declared it and
the runner verified the declaration against the graph: see [No-code
outcomes](#no-code-outcomes-scoped-and-stale-premise) below.

A gated item **keeps its worker slot** until the pipeline settles, and its
node is out of candidate selection — for every worker on the box, not just
the one holding it — for as long as it is gating. A failed or blocked
pipeline cools the item off for `work.retryAfterMs` on the machine, and
**demotes it on the graph** (see [A refusal is graph
state](#a-refusal-is-graph-state-not-a-machine-local-cooldown)), because a
cooldown is machine-local and a refusal must not be.

## Command gates — the trusted-ref suite, and the protected-path lane

A command gate:

1. reads the change under judgement from the run's own working tree —
   `merge-base(trusted_ref, HEAD)..HEAD`, committed work only. Uncommitted
   changes to tracked files refuse the gate rather than being judged, but
   earn **one commit-or-discard round-trip** first: a fix-cycle dispatch
   into the run's own checkout, told to commit what belongs to the item and
   discard what does not. Only that dirty-tree case earns the round-trip —
   a missing checkout or an unresolvable trusted ref escalates directly;
2. **fails closed** if that change touches any declared `protected_paths`
   glob — the suite is not run, no fix cycle is offered, and the test
   change is filed as its own queue item carrying `profile: <test_lane_profile>`,
   which both `spor work` and `spor dispatch --from-queue` read back and
   dispatch under as if `--profile <lane>` had been passed;
3. otherwise materializes a throwaway git worktree at the implementer's
   commit, **forces every protected path back to the trusted ref's copy**
   (files the branch added under one are removed), stages the tree with the
   repo's own `dispatch.worktreeSetup` hook (seeing `SPOR_TREE_ROLE=gate`
   beside the rest of the hook env), and runs the declared `command` there.

Fields beyond `command`:

| Field | Means |
| --- | --- |
| `risk` | arms the gate only when the change touches a declared risk class; an unarmed gate records `skipped`, a fact, not a pass by omission |
| `serialize: "repo"` | takes the repo's lease around the suite so two gate trees, or a gate tree and an integration landing, never collide; fail-open on an unavailable lease |
| `reruns` | default `0`, at most `3` — the same command reruns on the **same** prepared tree before a failure counts as one, so a flake costs one more run instead of a fix cycle. A pass on a rerun is still recorded with the first failure as evidence |

The suite's environment names what it is judging: `SPOR_GATE_BASE` /
`SPOR_GATE_HEAD` (the shas), `SPOR_TRUSTED_REF`, `SPOR_GATE_STAGE` (`gate`,
or `integration` for the merge-queue candidate suite), `SPOR_GATE_NODE`,
`SPOR_GATE=<id>`, `SPOR_GATE_ATTEMPT` (1, or N+1 for the Nth rerun), and
`CI=1`.

## Agent-review gates — a verdict that is read, not asserted

The runner composes the review dispatch itself: a launch under the gate's
declared `profile` (cross-model by convention), **read-only** — Codex's
`--sandbox read-only`, Claude Code's plan permission mode, OpenCode's plan
agent plus a denied shell, Copilot's denied write and shell tools — with a
prompt carrying the work item's text, the bounded diff, the gate's
`instructions`, and, on a fix cycle, the prior findings and the fix
dispatched at them. It ends with a fixed verdict shape:

```json
{
  "verdict": "pass" | "changes_requested",
  "prior": [{ "id": "F1", "status": "resolved" | "open", "note": "..." }],
  "findings": [
    {
      "severity": "blocking" | "major" | "minor",
      "file": "...",
      "summary": "...",
      "evidence": "the command/test run and what it showed",
      "introduced_by_fix": true | false
    }
  ]
}
```

The runner parses this block **in code**. Fail-closed throughout: a review
that could not be dispatched, never finished, left no readable report, or
whose verdict is unparseable is a gate **failure** — an unread review is not
an approval. Nor is a review of nothing: a branch carrying no committed
change against `trusted_ref` fails the gate closed and unretried, straight
to a person, since no reviewer is dispatched at an empty diff. Like a
command gate, a review gate may declare `risk` to arm conditionally — an
unarmed review skips a whole model dispatch, not just a suite run — except
that the empty-diff refusal always runs first, an unreadable diff still
fails a gate that declares risk closed, and a gate whose finding ledger
holds an open blocking finding runs regardless of arming.

**The gate is stateful and bounded**, to stop a memoryless reviewer raising
a new blocking finding every cycle instead of converging:

- **only `blocking` findings block.** Everything else is advisory, recorded
  and handed to the fixer as a note. A `changes_requested` with no findings,
  or with findings the parser cannot read, is itself unreadable and fails
  closed for the prior set only;
- **a blocking finding must be demonstrated** — a non-empty `evidence`
  string naming what was run. One without it is downgraded to advisory,
  recorded as claimed-but-not-shown; a later review may still demonstrate it
  by its id;
- **every prior finding is answered first.** The runner keeps a finding
  ledger (`F1, F2, …`, minted once, never reused) and hands each review its
  open blocking entries as `prior`; a verdict that ignores one is unreadable
  and counts as `changes_requested` for the prior set only, so nothing the
  memoryless verdict raised fresh is admitted instead;
- **a carried finding names the mechanism, not the next row.** Confirming a
  prior finding open is asked to enumerate the remaining `rows` of the
  mechanism it is an instance of; once a finding has been carried two fix
  cycles the list is required, and a confirmation naming fewer rows is
  flagged `row-by-row` on the ledger and the fact.

**Every finding carries a `category`**, folded onto the ledger:

- `correctness` (the default) — the change is wrong; a fixer fixes it.
- `unmet-condition` — the change is not wrong, but the work item's own
  stated done condition is unmet. A fixer does not argue it: it makes a
  fresh, materially different attempt, or a person re-scopes the item via a
  `decision`. Once such a finding survives two fix cycles the refusal is
  returned `noRetry` — no further implementer is dispatched at it, and it
  goes to the rescue lane (if declared) or straight to human escalation.
- `unrequested-mechanism` — the defect is real but lives in mechanism the
  item's own acceptance never required, where *removing* that mechanism
  would also satisfy the finding (the removal test is the whole category).
  Such a finding is always **advisory, never blocking**, however well
  demonstrated — the escape valve for fix cycles growing surface that each
  next review then attacks. The fixer is told to delete the mechanism, not
  harden it.

On `changes_requested` with cycles left, the runner dispatches an
implementer **fix cycle** at the same node, in the same tree, waits for it,
re-reads the diff, and re-runs the gate with the ledger and that fix in
hand. The declared `cycles` cap counts fix dispatches — `cycles: 3` means
the initial review plus three fix cycles, four reviews total. At the cap the
gate **escalates**, a `requires: [human]` queue item carrying the cycle
history and the ledger — unless the factory declares a [rescue
lane](#the-rescue-lane-a-strong-model-step-before-any-human-escalation),
which runs first and escalates only if it also fails.

## Human gates — approval keyed on declared risk

A human gate declares the `risk` classes that **arm** it (none declared =
unconditional). If the change touched none, the gate is `skipped` and
recorded as such. If it did, the runner files an approval item —
`requires: [human]`, so no worker can ever claim it — naming the risk
classes and paths, and blocks the resolve while polling it:

- the approval item gains a **live resolving edge** → **approved**, the gate
  passes — a bare status flip is not an approval, the same rule the
  terminal-states contract applies to a worker's own claim of completion;
- it reaches any other terminal status (`abandoned`, `closed`,
  `superseded`, …) → **refused**, the gate fails, and the approval item
  itself is the human record;
- nobody answers inside `approval_timeout_ms` (default 24h) → the pipeline
  reports **blocked**, the approval item stands, and the worker moves on
  rather than deciding on the person's behalf.

## Every gate outcome is a graph fact

Each gate — passed, skipped, failed, fail-closed, or blocking — writes one
artifact node `art-gate-<gate>-<stem>-<short-run-id>`, `relates-to` (never
`resolves`) the work item, carrying the verdict, the cycle history, and the
evidence. Deterministic and idempotent: the same gate recorded twice for one
run is one node. A graph that refuses the write does not change the
verdict — the enforcement is not the bookkeeping, and the runner says so
rather than claiming a fact it could not write. `spor work --status` reads
the same story back per worker: what is gating now, the pass/fail/blocked
tally, and why a gated item was cooled off.

A long-running `spor work` keeps executing the code it loaded at startup
however far the checkout moves afterwards, so it logs a one-line notice the
first time the watched ref (the factory's own integration `target_ref`,
else the loaded branch, else `HEAD`) moves past the loaded commit. It never
restarts itself unless `--restart-on-land` (`work.restartOnLand`) is set —
for a self-hosting factory whose worker runs from the very checkout its own
pipelines land onto — in which case it drains (finishes every in-flight run
and gate pipeline, abandoning none) and exits cleanly for a supervisor to
restart on the new code.

## A refusal is graph state, not a machine-local cooldown

A gate necessarily runs *after* the run wrote its resolver, so a refused
claim is one the graph is already carrying as finished. Cooling the node off
locally says nothing to any other reader, so a failed or blocked pipeline
also **demotes the item on the graph**, in two parts, written as one act in
that order:

- the person's item the gate filed (escalation, approval, or test-change
  lane) carries **`blocks`** onto the work item — a live `requires: [human]`
  queue item naming the work item as its dependent, so the refusal is a
  graph fact any reader can follow;
- the work item's own **completion status is rolled back** to `open`, so
  status-derived surfaces (`spor get`'s ⚠, work analytics, `spor work
  --status`) stop reporting the refused claim as finished. Only a claim of
  completion is touched — a deliberately `abandoned` item is never reopened.

What the rollback deliberately does **not** do is put the item back in the
queue: queue liveness is derived from the resolving *edge*, never the
status, and this runner never retracts an edge — the resolver stays as the
agent's durable record of what it did, and a person who agrees with the
gate retires it themselves. A passing gate never re-flips status back either
— that would be the runner asserting completion, which a gate does not do.

Fail-soft, like the fact write: if the escalation write itself fails, the
item's status is left exactly as the run left it, the gate fact records
`Demotion: not attempted` and why, and the run record carries
`gate_escalation_failed: true`. A **bounded auto-retry** re-attempts only
that write (and the demote that follows it) on a doubling backoff
(`work.escalationRetryBackoffMs`, default 5m, capped by
`work.escalationRetryMaxBackoffMs`, default 1h) for up to
`work.escalationRetryMaxAttempts` (default 5) — never the pipeline itself.
The manual door once that gives up, or once the graph is writable again by
hand, is `spor work --regate <run-id> --factory <id>`: it re-runs the
factory's gates (and the integration stage) on that same finished run, and
its facts carry the attempt in their ids (`…-r2-…`) so the first verdict's
record is never overwritten. It refuses a run that is still running, one
carrying no claim of completion, and one that already settled a pass.

## An interrupted pipeline is resumed, not lost

A gate pipeline is the one piece of work the worker *process* owns, so a
worker that is stopped or killed abandons it — and the run it was judging is
already terminal, so no candidate poll would ever return to it. Left there
the claim stands permanently un-judged, which a factory exists to prevent.

Each pipeline stamps **`gate_state`** on its run record — `running`,
`interrupted` on a stop, or a settled verdict (`passed` / `failed` /
`blocked` / `superseded` / `scoped` / `parked`, the last from a
`propose`-mode integration landing — see below) once it reports; a settled
verdict is final for that run. A gate-armed worker joins that with its own status file
at each pass, before taking new work: a slot held by a worker that is no
longer live, whose run record is terminal, carries a claim worth gating, and
has no settled `gate_state`, is adopted and re-gated.

A resumed pipeline **re-runs its gates from the first one**, but every
gate's own progress — its finding ledger, fix-cycle count, attempt history,
and any fix in flight — is saved as `gate_progress` on the run record and
read back, so the cap holds across the interruption rather than being
granted afresh by it. Before any gate runs on a resumed (or checkout-gone)
pipeline, the runner checks whether the item was already **landed by
hand** while orphaned: if the graph says the item is resolved *and* git says
the run's head is contained in `trusted_ref`, the pipeline settles
**`superseded`** instead — no gate fact, no escalation, no demotion, and
`--regate` has nothing to re-judge. Every doubt here falls closed to the
ordinary refusal.

## The integration step: a code-enforced merge queue after every gate passes

A gate-passed, resolved branch is not yet shipped work — something still
has to land it. The `integration:` block closes that gap: a declarative
merge queue the runner enforces in code, run only after every declared gate
has passed. It is opt-in exactly like the gate list — a factory with no
`integration:` block resolves work exactly as the sections above describe.

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
| `mode` | `local` CAS's a local ref with `git update-ref`; `push` pushes to a remote, whose non-fast-forward rejection *is* the compare-and-swap; `propose` opens a pull request instead of mutating `target_ref` at all |
| `command` | the full suite, run on the merged candidate tree — never a fast tier deferred to a service after landing |
| `strategy` | `merge` \| `squash` \| `rebase` — how the candidate tree is built |
| `serialize` | the lease's scope; `repo` is the only value today |
| `reruns` | default `0`, at most `3` — the same bounded same-tree rerun a command gate has |

**The candidate build.** A throwaway worktree at `merge(target_ref,
branch)` per the declared `strategy`. A merge conflict is a **fix-cycle
event, not a terminal error** — fed back to the implementer through the same
cycle-cap-then-escalate machinery a failing gate uses. Every declared
`protected_paths` glob is forced back to the trusted ref's copy before the
suite runs, exactly as a command gate's tree gets — and because that restore
only rewrites the working directory, when it changes anything the stage
re-commits the restored tree and lands *that* sha rather than the
pre-restoration one.

**Landing is compare-and-swap**, and losing the race is nobody's mistake: a
lost race rebuilds the candidate against the ref's new tip and reruns,
automatically, never charged against the fix-cycle cap. **Every landing or
failure is a graph fact**, `art-merge-…` — the integration stage's twin of a
gate's `art-gate-…` fact, `relates-to` (never `resolves`) the work item. A
failure that exhausts its fix cycles demotes the item exactly as a failed
gate does (see [A refusal is graph
state](#a-refusal-is-graph-state-not-a-machine-local-cooldown)).

**`mode: propose`** runs the identical candidate build, protected-path
restore, and full suite — only the landing step differs: it pushes the
implementer's own branch and opens a PR against `target_ref` through the
`gh` CLI, checked as a declared capability. Opening the PR **parks** the
item rather than resolving it — a tracking item files the same `blocks`
demotion a failed gate would, and the work-loop slot frees immediately, no
in-process poll held. Resolving a parked item is a wholly separate later
pass (`checkProposal`, part of `spor work`'s own loop): a merged PR writes a
second `art-merge-…` fact carrying a `resolves` edge onto the tracking item
and restores the work item's completion status; a PR merged onto an
unexpected base or closed without merging leaves the tracking item for a
person. The full field-by-field propose-mode contract — the satisfiability
check, the parking/healing mechanics, and the per-pass `checkProposals`
reconciliation — is on [Worker protocol → The integration
step](/reference/worker-protocol/#the-integration-step-a-code-enforced-merge-queue-after-gates).

## The rescue lane: a strong-model step before any human escalation

A failing gate does not escalate on the first refusal — cycles against the
gate's own declared cap run first. Only once that budget is spent (or the
refusal is not one a fix cycle could address at all) does the gate
escalate. The **rescue lane** is an optional, factory-level step that runs
in between — one strong-model pass, dispatched before that escalation ever
fires. It is declared once, covering every gate's exhaustion rather than
being configured per gate:

```json
{
  "rescue": {
    "profile": "profile-claude-fable",
    "attempts": 1,
    "await_ms": 3600000,
    "instructions": "…"
  }
}
```

| Field | Means |
| --- | --- |
| `profile` | required — the profile the rescue dispatches under. A strong model by intent, profile-routed like an agent-review gate |
| `attempts` | default `1`, at most `3` — rescue attempts per pipeline. A second attempt is handed the first's diagnosis and asked why it did not land |
| `await_ms` | default one hour — how long the runner follows the rescue run before treating it as unrun |
| `instructions` | optional factory-specific guidance added to the rescue's prompt |

**When it runs.** Only when a pipeline would otherwise escalate to a
person. A protected-path hit (already routed to its test-change lane) and a
human gate's rejected or still-pending approval have each already filed
their own person-facing item, so there is nothing fresh for a rescue to get
ahead of; a `declined` run is never gated at all, so it is never rescued
either.

**What it does.** Dispatched into the run's own checkout, always
supervised, with the work item, the diff, every commit on the branch, the
refused gate's evidence, the fix-cycle history, and any earlier rescue's
diagnosis. It is asked to:

1. **diagnose** the refusal into one of four categories — `reviewer-drift`,
   `real-defect`, `stale-premise`, or `environment`;
2. **fix** it in that checkout and commit, naming the findings it addressed,
   or change nothing it cannot justify; and
3. **file** at least one Spor task proposing the factory, gate, prompt, or
   item change that would have prevented the pattern.

It is told, and it is true, that it never marks a gate passed itself.
Reading its diagnosis is deliberately fail-soft — a rescue that fixed the
tree but forgot to state a category still gets its fix judged. A rescue
that could not be dispatched, or never reached a terminal state inside
`await_ms`, is recorded as unrun, and the refusal it was handed escalates
exactly as it would have with no rescue lane.

**After the rescue,** the runner re-runs the whole gate list — every gate,
from the first, on the tree the rescue left — as a fresh pass keyed to the
rescue attempt. Each gate gets a fresh fix-cycle budget, but the finding
ledger from before the rescue carries forward, so a review after a rescue
is a review under the same stateful fix-cycle protocol as any other. If the
rescue pass passes, the item stands — nothing escalates, nothing is
demoted, and the integration step follows as usual. If it refuses and
attempts remain, the next attempt is handed everything above plus the
earlier diagnoses; once attempts are exhausted the escalation fires, and its
body opens with the rescue's diagnosis, so the person reads what a strong
model already concluded before deciding.

## No-code outcomes: scoped and stale premise

A run that reads the ground and finds its item's premise stale can
legitimately end with an empty diff — but a review gate cannot tell that
from a run that did nothing, so it fails closed on the empty diff by
default. A run may **declare** a no-code outcome instead, which the runner
**checks** against the graph rather than taking at its word:

- **a node**, an `artifact`, carrying `outcome: rescoped | premise-stale |
  duplicate` in its frontmatter, an edge to the work item, and — for
  `premise-stale`/`duplicate` — an edge to the node that makes the item
  stale;
- **the fixed line**, first in the run's final message:
  `SCOPED: <outcome> <the node id> — <one-line reason>`. `SCOPED:` and
  `DECLINED:` are mutually exclusive by construction and by meaning — a
  decline says the item is wrong and claims nothing; a scoping result
  claims the item's real work is done and shows a graph write for it.

Before any gate runs, the runner verifies: the diff really is empty, the
report carries the fixed line with a recognized outcome word, the named
node declares the same `outcome:` and edges the item, and — the load-bearing
check — **the item itself moved**: for `rescoped` its `repo:` stamp now
differs from the one this pipeline claimed it under; for
`premise-stale`/`duplicate` that or a supersession asserted by some *other*
node. A live resolving edge alone, or a supersession the declaring node
asserts of itself, does not count — both are writes a run doing nothing
could make for free.

If it checks out, the pipeline settles **`scoped`** — a reserved gate id,
an idempotent `art-gate-scoping-…` fact, no code gate and no integration
stage run, no escalation, no demotion. It is deliberately not `passed`, and
it does **not** restore a completion status a prior refusal rolled back,
since the verified claim is that the item is still open (re-stamped, or
superseded) rather than done. Like any other settled state it cools off for
`work.retryAfterMs` rather than being re-dispatched immediately. If the
declaration does not check out, the pipeline falls straight through to the
ordinary empty-diff refusal, now carrying the run's own account plus the
check that broke it — a declaration can only ever remove a wrong
escalation, never manufacture a pass.

**Stale premise needs no declaration at all** when an item's own `commits:`
stamps are already landed on `trusted_ref` before the run was ever
dispatched (typically because a sibling task's fix happened to also touch
this item's code). The runner checks the diff is empty and every one of the
item's `commits:` stamps it can verify is an ancestor of `trusted_ref`; if
so it settles `scoped` exactly as the declared route does, labeled
`already-landed` rather than one of the three declared words. An item
carrying no `commits:` at all — the overwhelming case — is unaffected.

## See also

- [Worker protocol](/reference/worker-protocol/) — the claim/brief/work/report/resolve
  contract a factory's gates and integration step sit on top of, including
  the full propose-mode field reference and posture-translation rules the
  rescue lane uses.
- [Dispatch, capabilities, and profiles](/reference/dispatch/) — profiles,
  machine capabilities, and the `requires:` risk register a review or human
  gate's `risk` classes build on.
- [Dispatch → work](/reference/cli/dispatch/#work) — the `--factory`,
  `--status`, and `--regate` flags.
