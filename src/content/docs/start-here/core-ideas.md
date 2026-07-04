---
title: Core ideas
description: The graph model — typed nodes, typed edges, and the loop that keeps context alive.
sidebar:
  order: 6
---

**Use this when** you want the model behind what the quickstarts did: what a
node and an edge are, and why Spor uses a graph rather than a list of notes.

**You do not need this if** you are mid-quickstart; the [Start
here](/start-here/) paths work without this page, and the model can wait
until the tool is running.

**After reading this, you should be able to** distinguish nodes from edges,
describe the orient-traverse-commit loop, and choose the deeper reference
page for a graph-model question.

Spor keeps each durable work outcome for a team as one record: decisions,
deferred tasks, resolved issues, conventions, and unanswered questions. [What
is Spor?](/start-here/what-is-spor/) gives the plain-language introduction;
this page assumes that framing and adds the model behind it. Each recorded
fact is one markdown file called a node. Nodes are joined by typed,
directional links called edges, which carry why a node exists, what it
depends on, and what replaced it.

## Why a graph, not a list

A ticket or a note is a container: its prose is frozen at the moment of
writing, and it rots as the project moves. A Spor node is a pointer into a
living structure. When the tidefall team supersedes `dec-tidefall-retry-once`
with `dec-tidefall-billing-retries`, every briefing that touches the old decision sees
the supersession, because it is an edge rather than a sentence someone has to
remember to update.

Typed edges also carry direction and strength. `supersedes` and
`constrained-by` are strong claims that traversal follows aggressively;
`relates-to` and `mentions` are weak associations that fade quickly. That
weighting is what lets Spor compile a briefing by walking structure instead
of guessing from text similarity alone.

## The loop

Every Spor surface — the CLI, the REST API, the MCP tools an agent calls —
works the same three-phase loop:

1. **Orient.** Find where to start: search the graph, read the ranked
   decision queue, or take the briefing injected at session start.
2. **Traverse.** Walk outward from a starting node, gathering the lineage
   that matters: the decisions still in force, the approaches already
   rejected, the open blockers.
3. **Commit.** Write the outcome back — a decision, a deferred task, an
   answer — so the next session inherits it instead of rediscovering it.

The graph is versioned because its home is a git repository: node history is
commit history, timestamps derive from commits, and every write is
attributed to the person or agent that made it.

## Where to go deeper

| Page | What it explains |
| --- | --- |
| [The node model](/reference/graph-model/nodes/) | One fact per node, ids, summaries, timestamps, and the resolver gate |
| [Node types](/reference/graph-model/node-types/) | Every node type in the registry, with prefixes and roles |
| [Edge types](/reference/graph-model/edges/) | Every edge type, its direction, weight, and inverse forms |
| [The decision queue](/use-spor/queue/) | Derived ranking signals, human priority, dormancy, and per-person views |
| [Briefings and corrections](/use-spor/briefings/) | The compiled context packet and how to fix it when it is wrong |
| [Capture and ingestion](/use-spor/capture/) | Raw text in, typed nodes out — the low-friction write path |
| [Review what changed](/use-spor/review-what-changed/) | The recent-activity feed, one node's history, tracing a commit to its reasons, and the program view |
| [Ask and answer questions](/use-spor/ask-and-answer-questions/) | Filing a question, steward routing, and the `answers` edge that closes it |
| [Schemas are nodes](/reference/graph-model/schemas/) | Extending the ontology by writing schema nodes into the graph |
| [Local and remote mode](/reference/graph-model/local-and-remote/) | The two deployment shapes and the configuration cascade |
| [Identity and attribution](/use-spor/identity/) | People, organizations, and agents acting on behalf of people |
| [Claims and leases](/reference/graph-model/claims/) | How concurrent workers avoid doing the same task twice |
| [Dispatch, capabilities, and profiles](/reference/dispatch/) | Briefed background agents and substitution-free routing |
| [Lenses, program view, and workflows](/reference/graph-model/lenses-and-workflows/) | Saved views, the progress tree, and workflow runs |
| [Repos, projects, and the gardener](/reference/graph-model/repos-and-projects/) | Two-layer grouping and the automated hygiene sweep |
