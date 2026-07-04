---
title: What Spor is not
description: The product's boundaries — six things Spor does not try to be, and where to go if you wanted one of them.
sidebar:
  order: 7
---

Spor uses vocabulary that also appears in ticket trackers, wikis, chat tools,
and search systems. Those overlaps can make the first 30 minutes confusing, so
this page names the boundaries and shows what to keep using alongside Spor.

## Spor is not a ticket tracker

You might expect task and issue nodes to make Spor a ticket tracker. Spor has
task and issue nodes, short markdown files that each hold one fact, and
`spor next` shows [the decision queue](/use-spor/queue/) compiled from graph
signals: what an item blocks, recent activity in its neighborhood, and age,
blended with a human-set priority. There are no sprints, story points, or
swimlanes to administer. Spor records why work exists, what
constrained it, and what settled it. A team that wants sprint planning keeps
its tracker; Spor sits alongside it and records the decisions and lineage the
tracker loses.

## Spor is not a wiki

You might expect Spor to replace the wiki where a team keeps long-lived
explanations. A wiki page is a living document someone has to keep current,
and it rots silently when nobody does. In Spor, a node records one short fact,
and an edge is a typed directional link between facts; currency is carried by
edges instead of edits, as described in [the node
model](/reference/graph-model/nodes/). When a decision is superseded, the
supersedes edge makes every briefing that touches the old decision show the
replacement, with no page for anyone to remember to update. Long-form design
docs still belong in a wiki or docs repo; Spor nodes can point at them.

## Spor is not a chat transcript archive

You might expect Spor to preserve the conversation that happened during a
coding session. Spor does not store conversations. At the end of a coding
session, a distiller writes back the durable outcomes, typically one or two
nodes: a decision that got made, an approach that was rejected, or a follow-up
that was deferred. Briefings are compiled from those outcomes, so the next
session inherits conclusions, not chat to re-read; [what happens
automatically](/use-spor/what-happens-automatically/) covers that flow.
Session logs, if wanted, live in the coding agent's own history.

## Spor is not just RAG over docs

You might expect Spor briefings to work like retrieval-augmented generation
over docs. Retrieval-augmented generation embeds text and returns passages
that look similar to the question. Spor's briefing compiler walks typed,
weighted edges, following strong claims like supersedes and constrained-by
further than weak associations like relates-to, so a briefing can state that
an approach was superseded or rejected, which text similarity alone cannot
know. Content relevance is one arm of the compile, not the whole method;
[briefings and corrections](/use-spor/briefings/) explains the briefing
surface.

## Spor is not a replacement for human judgment

You might expect a ranked queue and compiled briefings to decide what the team
should do. The queue ranks open work, but a person decides what matters: the
human-set priority field is the strongest single ranking signal, precisely
because the graph knows structural urgency and not business value. Briefings
can be wrong, and standing corrections exist because a person is expected to
notice and fix them. Spor records decisions; the team makes them. Use [the
decision queue](/use-spor/queue/) for ranking open work and [briefings and
corrections](/use-spor/briefings/) for correcting context.

## Spor is not where private server/operator setup lives

You might expect public product docs to include deployment and operator pages
for running the server side. These docs describe using Spor: the CLI, the REST
API, the MCP connector, and the hosted product as its members and admins see
it. Running the server side is deliberately not documented here, and that
absence is a boundary, not a gap. Local mode needs no server at all; the graph
is a plain git repository on your machine. For the team product, [Hosted
Spor](/hosted/) covers what a member or admin sees, and [Start
here](/start-here/) covers the user-facing entry points.

