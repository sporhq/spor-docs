---
title: Core ideas
description: The graph model — typed nodes, typed edges, and the loop that keeps context alive.
sidebar:
  order: 6
---

Spor is a typed, versioned knowledge graph of the durable outcomes of work.
Each node is a markdown file recording one fact: a decision that was made, a
task that was deferred, an issue and how it was resolved, a convention the
team holds, a question nobody could answer yet. Typed, directional edges
connect them, so the graph carries what a flat list of notes cannot — why a
node exists, what it depends on, and what replaced it.

## Why a graph, not a list

A ticket or a note is a container: its prose is frozen at the moment of
writing, and it rots as the project moves. A Spor node is a pointer into a
living structure. When a team supersedes `dec-export-json-only` with
`dec-export-csv-format`, every briefing that touches the old decision sees
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
| [Capture, ingestion, and questions](/use-spor/capture/) | Raw text in, typed nodes out; routing questions to the person who knows |
| [Schemas are nodes](/reference/graph-model/schemas/) | Extending the ontology by writing schema nodes into the graph |
| [Local and remote mode](/reference/graph-model/local-and-remote/) | The two deployment shapes and the configuration cascade |
| [Identity and attribution](/use-spor/identity/) | People, organizations, and agents acting on behalf of people |
| [Claims and leases](/reference/graph-model/claims/) | How concurrent workers avoid doing the same task twice |
| [Dispatch, capabilities, and profiles](/reference/dispatch/) | Briefed background agents and substitution-free routing |
| [Lenses, program view, and workflows](/reference/graph-model/lenses-and-workflows/) | Saved views, the progress tree, and workflow runs |
| [Repos, projects, and the gardener](/reference/graph-model/repos-and-projects/) | Two-layer grouping and the automated hygiene sweep |
