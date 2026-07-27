---
title: Node types
description: Every node type in the schema registry, with its id prefix and role in the graph.
sidebar:
  order: 2
---

**Use this when** you are choosing the type for a node written by hand or via
`put_node`, interpreting an unfamiliar id prefix, or checking which statuses
a type allows.

**You do not need this if** you write through capture; the server picks the
type for you, as described in [Capture and ingestion](/use-spor/capture/).

**After reading this, you should be able to** name the type behind any id
prefix, say which statuses a type allows and which types join the queue, and
read the live registry with `spor schema`.

Node types are defined by the schema registry, not hardcoded. A fresh graph
is born with the seed schema pack below; a team extends or overrides it by
writing its own schema nodes (see [Schemas are nodes](/reference/graph-model/schemas/)).
To read the live registry for your graph — seed plus any resident
overrides — run `spor schema`, or `spor schema <type>` for one type's
details.

## Work and knowledge types

These are the types sessions read and write every day.

| Type | Prefix | Role |
| --- | --- | --- |
| `decision` | `dec-` | A choice that was made, with the why. Statuses: `active`, `superseded`, `rejected`, `settled` (`settled` means still in force but acknowledged as background context). |
| `task` | `task-` | Active or planned work. Statuses: `open`, `active`, `done`, `abandoned`. Reaching `done` requires a resolver — see [the node model](/reference/graph-model/nodes/). |
| `issue` | `issue-` | A defect or finding and its resolution lineage. Statuses: `open`, `active`, `resolved`; `resolved` requires a resolver. |
| `incident` | `inc-` | Something that went wrong in operation. Live incidents join the decision queue. |
| `artifact` | `spec-`, `art-` | A document, spec, module, or build product worth referencing. Valid statuses (or none, for a plain reference doc): the delivery stages `in-review` / `approved` (non-resolving) and `merged` / `released` (resolving), plus two non-delivery lifecycle values for a doc rather than a change — `active` (a living, current reference doc) and `done` (terminal — a finished doc/spec/build product). Status membership is write-gated — see [the node model](/reference/graph-model/nodes/#status-vocabulary-is-write-gated-separately-from-transition-legality). |
| `norm` | `norm-` | A standing convention or constraint. Norms ride along in every project-relevant briefing without needing to match the query, and can declare [coupling anchors](#coupling-norms) — file globs that pair artifacts that must change together. |
| `question` | `question-` | A routed ask the graph could not answer. Statuses: `open`, `answered`. Routed to the steward of the closest relevant node. |
| `capture-pending` | `cap-` | Raw captured text that fit no schema, preserved for later triage. Closed only as `merged` (content moved into proper nodes) or `rejected` (no durable fact). |
| `finding` | `find-` | A gardener observation about another node, filed as a queue item — see [the gardener](/reference/graph-model/repos-and-projects/). |

## System and provenance types

| Type | Prefix | Role |
| --- | --- | --- |
| `briefing` | `brief-` | A compiled briefing — output of the system. Never traversed by the compiler, so briefings don't feed back into briefings. |
| `correction` | `corr-` | A standing fix to a briefing: pins, excludes, and guidance. Also never traversed. |
| `schema` | `schema-` | A schema definition — the type that makes the ontology data. Recognized natively by the core. |

## Identity and grouping types

| Type | Prefix | Role |
| --- | --- | --- |
| `person` | `person-` | An org member's identity anchor: the canonical subject tokens bind to, and the target of routing and assignment edges. |
| `organization` | `org-` | A durable organization identity anchor; people connect to it with `member-of-org` (membership) and `stewards` (admin authority). |
| `agent` | `agent-` | A person-owned automation principal — the durable identity of a dispatched background session, owned via an `owned-by` edge. |
| `repo` | `repo-` | Durable git-repository identity: slug aliases plus repo fingerprints, so a rename heals at read time. |
| `project` | `proj-` | A stable grouping above repos. A repo joins its one home project with a `grouped-under` edge. |

## Automation types

| Type | Prefix | Role |
| --- | --- | --- |
| `profile` | `profile-` | A reusable runtime-plus-capability bundle an agent dispatches under (harness, model, skills, plugins, MCP servers). Its fields are the dispatch satisfiability spec. |
| `routine` | `routine-` | Owner-scoped trigger-to-action automation: declarative when/do rules over graph events that dispatch only the owner's agents. |
| `workflow` | `wf-` | A repeatable, reviewable automation definition — a DAG of steps that lives in the graph, versioned and proposal-gated. |
| `workflow-run` | `run-` | One execution of a workflow: its state and lineage. Live runs surface in the queue when stuck. |

## View types

| Type | Prefix | Role |
| --- | --- | --- |
| `lens` | `lens-` | A saved view over the graph: declarative query and render blocks, optional actions — see [Lenses](/reference/graph-model/lenses-and-workflows/). |
| `workspace` | `workspace-` | A composition of lenses into one layout, rendered as a single view. |

## Flags that shape behavior

Each type's schema declares a handful of flags the rest of the system reads:

- **`queueable`** — live nodes of this type join the decision queue
  (`task`, `issue`, `incident`, `question`, `capture-pending`, `finding`,
  `workflow`, `workflow-run`).
- **`always_on`** — rides along in every project-relevant briefing (`norm`).
- **`traversable: false`** — the compiler never walks through it
  (`briefing`, `correction`, and the view types).
- **`capturable: false`** — never drafted from captured text; created only
  deliberately (`person`, `repo`, `agent`, `profile`, and the other
  identity, automation, and system types).

Run `spor schema` to see which flags each type carries in your graph's live
registry.

## Coupling norms

A norm becomes a **coupling norm** by declaring two file-glob lists: when
files matching `couples_when` change, the artifacts in `couples_also` should
change in the same edit — or be consciously dismissed. The tidefall team
pairs its API handlers with the reference page that describes them:

```yaml
couples_when: [src/api/**]
couples_also: [docs/api.md]
```

Globs are repo-root-relative: `**` crosses path segments, `*` stays within
one, `?` matches one character, a trailing `/` means the whole subtree, and a
bare `docs/api.md` anchors at the repo root. An entry may be repo-qualified
as `<slug>:<glob>` to couple artifacts across repositories — a qualified
trigger fires only in that repo, while unqualified entries follow the norm's
own scope (its project, or its `applies_to_*` selectors). Both keys are
required; either alone does nothing, and `spor validate` warns.

Two consumers read the anchors. The [edit-time
hook](/use-spor/what-happens-automatically/#after-edits-coupling-reminders)
reminds a session the moment it edits a trigger file, and
[`spor check`](/reference/cli/reading-the-graph/#check) reports drift over a
whole diff, for CI and pre-commit.

For pairings where the coupled thing is a **value** that must agree — a
runtime version repeated in two files — add a machine-checkable invariant:

```yaml
couples_value_a: ".nvmrc#v?(\\d+)"
couples_value_b: "Dockerfile#FROM node:(\\d+)"
```

Each side is `<path>#<regex>`; the first capture group is the value. `spor
check` compares the two extracted values: agreement means the coupling is
satisfied even when one file went untouched, and disagreement is reported
even when both files were edited.

## Agent-readiness

Any queueable node — a task, issue, incident, and the rest of the
[queueable set](#flags-that-shape-behavior); schema-approval items are
excluded, since they have their own review lane — carries a second, derived
classification alongside status: `readiness: agent | human | untriaged`,
computed structurally in the queue's ranking pass. It is deliberately
*not* a status (that would overload the lifecycle vocabulary every consumer
already partitions on) and *not* an edge (`assigned → agent` pins who does
the work; readiness is about whether the spec is complete enough for anyone
to start unattended). It answers "can a coding agent complete this
unattended, or does it need a human first?":

- **`human`** — `requires:` includes `human` (see [the `requires:` risk
  register](/reference/dispatch/#the-requires-risk-register)); an
  `assigned → person` edge; a held task awaiting triage; the item is itself
  an open question or an unprocessed capture; or a live, unanswered question
  node sits in its 1-hop neighborhood.
- **`agent`** — an explicit `readiness: agent` frontmatter stamp, or an
  `assigned → agent` edge.
- **`untriaged`** — neither of the above. A deliberate third bucket:
  "nobody has checked the spec yet" must not default into either agent or
  human.

`human` is checked first and wins on conflict, which is what makes this
derivation-with-override rather than a plain hand-set flag that could drift
out of sync with reality: a `readiness: agent`-stamped item that later gains
an open question, or a `requires: human` edit, flips back to `human` on the
very next read.

The **only** hand-settable piece is the stamp itself — `readiness: agent`
plus its provenance (`readiness_by`, `readiness_at`, `readiness_via`), set
with [`spor ready`](/reference/cli/writing-to-the-graph/#ready) or
`POST /v1/nodes/{id}/readiness` and cleared the same way. There is no
hand-settable `readiness: human` value: human is always derived, never
stamped. A gap that can't be closed by writing nodes — an unbuilt
prerequisite, a profile no machine can currently satisfy — is instead
recorded as an explicit `blocks` edge, which genuinely removes the item from
the queue until the prerequisite lands; readiness only ever covers the
soft, derived side.

The queue surfaces the classification on every item where it is decisive —
`readiness` plus `readiness_reasons[]`, omitted entirely on an `untriaged`
item, so a graph with no readiness signal reads byte-identical to before —
and as an aggregate `counts_by_readiness` on the envelope. See [The decision
queue](/use-spor/queue/#agent-readiness-and-the-make-ready-loop),
[`spor next --readiness`](/reference/cli/reading-the-graph/#next), and
[`GET /v1/queue`](/reference/api/reads/#get-v1queue).
