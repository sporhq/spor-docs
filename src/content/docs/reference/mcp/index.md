---
title: MCP
description: The MCP surface — the operating loop, the tools, and the widget.
sidebar:
  order: 1
---

Spor exposes an MCP (Model Context Protocol) server at `/mcp`, so an AI
assistant — claude.ai, Cowork, Claude Code, or any MCP client — can work with
your team's knowledge graph directly. Connected, the assistant can:

- **Search the graph** for what the team already knows about a task, before
  designing or deciding anything ([`query_graph`](/reference/mcp/tools/#query_graph)).
- **Walk a node's neighborhood** — why it exists, what it depends on, what
  answered it ([`get_node`](/reference/mcp/tools/#get_node), root-mode
  [`query_graph`](/reference/mcp/tools/#query_graph), [`render_lens`](/reference/mcp/tools/#render_lens)).
- **Read the ranked decision queue** — open work ordered by graph signal, each
  item with a one-line why ([`show_queue`](/reference/mcp/tools/#show_queue)).
- **Write outcomes back** — a decision, a finding, a deferral — as typed,
  linked nodes the next session inherits ([`capture`](/reference/mcp/tools/#capture),
  [`put_node`](/reference/mcp/tools/#put_node)).

Every write is attributed to you. The server stamps the author from the
authenticated token, and any `author:` supplied in a payload is discarded — a
connected assistant can never write as someone else.

## Prerequisites

- **A Spor account on a team server.** Either your organization's own Spor
  server or the hosted product. The MCP surface is a door onto a shared org
  graph; there is nothing to connect to in purely local mode.
- **A person identity and a personal access token** (`spor_pat_…`), minted
  for you by a server admin. The connector's OAuth consent step asks you to
  paste this token once — see [Connecting](/start-here/connect-an-assistant/).
- **An MCP host that supports remote connectors** over Streamable HTTP with
  OAuth 2.1 — claude.ai and Cowork (custom connectors) and Claude Code both
  qualify. The [interactive widget](/reference/mcp/widget/) additionally needs a host
  with MCP Apps support (Claude, Goose, VS Code); other hosts get a text
  rendering of the same views automatically.

There is no anonymous access: unauthenticated MCP calls are rejected, because
every write needs an author.

## The tools

Twenty-three tools, framed by the server itself as an
[ORIENT → TRAVERSE → COMMIT loop](/reference/mcp/operating-loop/) rather than a flat
list. Full details in the [tool reference](/reference/mcp/tools/).

| Tool | What it does |
| --- | --- |
| [`query_graph`](/reference/mcp/tools/#query_graph) | Free-text search, or compile one node's neighborhood (`root_id`) |
| [`get_node`](/reference/mcp/tools/#get_node) | One node's full markdown, edges, and revision |
| [`node_history`](/reference/mcp/tools/#node_history) | One node's commit lineage — who changed it, when, and the patch |
| [`show_queue`](/reference/mcp/tools/#show_queue) | The ranked decision queue, as data — "what's next" |
| [`render_queue`](/reference/mcp/tools/#render_queue) | The same queue, with the interactive widget attached |
| [`recent_changes`](/reference/mcp/tools/#recent_changes) | What changed in the graph since a commit or a point in time |
| [`analytics`](/reference/mcp/tools/#analytics) | Created-vs-completed, throughput, cycle time, WIP, bottlenecks |
| [`schema`](/reference/mcp/tools/#schema) | Introspect the live schema registry — the contract as data |
| [`capture`](/reference/mcp/tools/#capture) | Raw prose in, typed and linked nodes out — the default write door |
| [`put_node`](/reference/mcp/tools/#put_node) | Create or update one node from full markdown |
| [`add_edge`](/reference/mcp/tools/#add_edge) | Add one typed edge between two nodes |
| [`remove_edge`](/reference/mcp/tools/#remove_edge) | Withdraw one edge |
| [`set_status`](/reference/mcp/tools/#set_status) | Change one node's status, gated by the schema |
| [`set_priority`](/reference/mcp/tools/#set_priority) | Set or clear the human priority override (p1–p3) |
| [`propose_correction`](/reference/mcp/tools/#propose_correction) | Pin, exclude, or add guidance to future briefings |
| [`ask_question`](/reference/mcp/tools/#ask_question) | File a question, routed to whoever stewards the closest node |
| [`run_workflow`](/reference/mcp/tools/#run_workflow) | Start a run of an active workflow |
| [`render_lens`](/reference/mcp/tools/#render_lens) | Run a named saved view (board, table, lineage tree) |
| [`render_program`](/reference/mcp/tools/#render_program) | Progress and gating tree for a workstream root |
| [`claim`](/reference/mcp/tools/#claim) | Take the heartbeat-renewed lease on a node so no one duplicates it |
| [`renew`](/reference/mcp/tools/#renew) | Bump your live lease's expiry — the heartbeat that keeps a claim |
| [`extend`](/reference/mcp/tools/#extend) | Manually stretch your lease for a known long idle gap |
| [`release`](/reference/mcp/tools/#release) | Drop the lease and return the node to the pool |

## In this section

Connector setup — adding Spor in claude.ai or Claude Code and the OAuth flow
you'll see — lives in [Connect an AI assistant](/start-here/connect-an-assistant/).

- [The operating loop](/reference/mcp/operating-loop/) — the ORIENT → TRAVERSE → COMMIT
  mental model the server teaches connected assistants.
- [Tool reference](/reference/mcp/tools/) — every tool: purpose, key parameters, when
  to reach for it.
- [The widget](/reference/mcp/widget/) — the interactive queue, lens, and program views
  on hosts that support embedded apps.
