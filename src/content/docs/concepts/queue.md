---
title: The decision queue
description: How open work is ranked — derived graph signals blended with human priority, plus dormancy and per-person views.
sidebar:
  order: 5
---

The decision queue answers "what should I work on next?". It is a compile
mode over the graph, not a separate store: collect every live node whose
type is queueable (tasks, issues, incidents, questions, pending captures,
findings, proposed schemas and workflows), score each one, and return a
ranked list where every item carries a one-line *why* — "blocks 3 open
tasks; anchors hot this week".

Reach it with `spor next`, the `show_queue` MCP tool, or `GET /v1/queue`.

## Derived signals, human priority

No single formula owns the ranking. Each item contributes derived signals,
blended with the human-set `priority:` field:

- **priority** — `p1`, `p2`, or `p3`, ordinary frontmatter set by a person
  (or an agent — the queue records who set it and says so in the why-line,
  rather than assuming human triage). Priority is the strongest single term:
  the graph knows structural urgency, it does not know business value.
- **blocking** — how much open work is reachable through this node's
  `blocks` edges. Unblockers rank up.
- **blocked_by** — the inverse: an item gated by a live, unresolved blocker
  is demoted below its own blocker in the same ranking and flagged
  `blocked`, naming what gates it. The unblocker always surfaces first.
- **heat** — recent activity in the node's neighborhood. Only work-class
  operations count (reads don't heat, so the queue can't heat itself), and
  heat enters the blend log-compressed so hundreds of touches cannot drown
  the other signals.
- **front** — the viewer's own recent writes on the node, so the thing you
  were working on yesterday stays near the top. Capped below the `p1` bump;
  human priority stays supreme.
- **staleness** — the node's anchors were superseded or deleted. High
  staleness flips the suggestion from "do" to "close": the graph moved on
  and the item probably should too.
- **age** — older items drift up slowly, capped so age alone never wins.
- **needed_by** — an optional `needed_by: YYYY-MM-DD` deadline ramps the
  score as the date approaches and caps once overdue. The visible-early
  counterpart of `wake`.

A schema can add org-specific signals in attached code, and a team can
replace the blend entirely with a queue-policy schema node — see
[Schemas are nodes](/concepts/schemas/).

Items already retired by a live inbound `resolves` or `answers` edge are
excluded from the queue no matter what their status field still says.
Structural truth wins over a lagging status flag; the gardener files a
finding asking a human to flip the field.

## Wake: scheduled dormancy

A queueable node may carry `wake: YYYY-MM-DD` — "nothing to do against this
until that date". Before the date the queue counts it as dormant instead of
ranking it; from the date on it surfaces to **every** viewer, flagged
`woke <date>` in its why-line.

This is the renew-the-certificate shape. The classic failure is a reminder
in one person's calendar: the owner leaves, the reminder leaves with them,
and the expiry becomes an incident. `wake:` keeps the schedule with the work
instead — no scheduler exists anywhere; the queue simply compares dates at
read time, and whoever looks after the wake date sees the item. A dormant
node is still live graph state: briefings and edges see it normally, only
queue ranking waits.

## The assignee view

By default the queue is scope-wide: everything live in the project (or, with
no project filter, every project at once). Passing an assignee narrows it to
the work one person carries — the union of nodes with an `assigned` edge to
them and the nodes they steward:

```bash
spor next                      # the ranked queue for this project
spor next --all-projects       # the cross-project firehose
```

Over the API, `GET /v1/queue?assignee=person-jo` answers a manager's "what
is Jo carrying?", and `assignee=me` binds to the caller. The carrying view
is deliberately narrower than the queue: for the ordinary "what's next"
answer, don't filter by assignee at all.

Two more per-viewer conveniences: a person node may carry a `queue_mute`
list (project slugs or node ids, each with an optional `@YYYY-MM-DD`
expiry) that hides those items from *their* queue only, and both mutes and
dormancy are always counted in the response — the queue reports what it hid,
never silently truncates.

## Suggestions, not verdicts

Each item carries a suggestion the signals imply: `do` for ready work,
`blocked` when a live blocker gates it, `close` when staleness says the
graph moved on, `triage` for a task held open with a recorded outcome but no
resolver and no blocker, `approve` for a proposed schema or workflow
awaiting review. The queue presents the evidence and the recommendation; a
person decides.
