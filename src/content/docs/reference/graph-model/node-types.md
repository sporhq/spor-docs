---
title: Node types
description: Every node type in the schema registry, with its id prefix and role in the graph.
sidebar:
  order: 2
---

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
| `artifact` | `spec-`, `art-` | A document, spec, module, or build product worth referencing. When it represents a change it may carry a delivery-stage status: `in-review` / `approved` (non-resolving) or `merged` / `released` (resolving). |
| `norm` | `norm-` | A standing convention or constraint. Norms ride along in every project-relevant briefing without needing to match the query. |
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
