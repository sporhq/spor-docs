---
title: MCP
description: The MCP surface — the operating loop, the tools, and the widget.
sidebar:
  order: 1
---

**Use this when** you are connecting an AI assistant to the graph over MCP,
or looking up an MCP tool's contract.

**You do not need this if** you work from a shell; the [CLI
reference](/reference/cli/) covers the same operations, and most tools have a
REST twin under [REST API](/reference/api/) — the widget-only
[`apply_lens_action`](/reference/mcp/tools/#apply_lens_action) and the
graph-browse [`explore_graph`](/reference/mcp/tools/#explore_graph) are the
two MCP-only exceptions, noted on their tool entries.

**After reading this, you should be able to** check the connector
prerequisites, name what a connected assistant can read and write, and find
the tool entries and widget page.

Spor exposes an MCP (Model Context Protocol) server at `/mcp`, so an AI
assistant — claude.ai, Cowork, Claude Code, or any MCP client — can work with
your team's knowledge graph directly. Connected, the assistant can:

- **Search the graph** for what the team already knows about a task, before
  designing or deciding anything ([`query_graph`](/reference/mcp/tools/#query_graph)).
- **Walk a node's neighborhood** — why it exists, what it depends on, what
  answered it ([`get_node`](/reference/mcp/tools/#get_node), root-mode
  [`query_graph`](/reference/mcp/tools/#query_graph), [`render_lens`](/reference/mcp/tools/#render_lens),
  [`explore_graph`](/reference/mcp/tools/#explore_graph)).
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

The tools, framed by the server itself as an
[ORIENT → TRAVERSE → COMMIT loop](/reference/mcp/operating-loop/) rather than a flat
list — one entry per tool in the [tool reference](/reference/mcp/tools/).

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
| [`explore_graph`](/reference/mcp/tools/#explore_graph) | Browse the graph's structure as nodes + typed edges — the birds-eye programs view, or walk outward from a node |
| [`capture`](/reference/mcp/tools/#capture) | Raw prose in, typed and linked nodes out — the default write door |
| [`put_node`](/reference/mcp/tools/#put_node) | Create or update one node from full markdown |
| [`add_edge`](/reference/mcp/tools/#add_edge) | Add one typed edge between two nodes |
| [`remove_edge`](/reference/mcp/tools/#remove_edge) | Withdraw one edge |
| [`set_status`](/reference/mcp/tools/#set_status) | Change one node's status, gated by the schema |
| [`set_priority`](/reference/mcp/tools/#set_priority) | Set or clear the human priority override (p1–p3) |
| [`propose_correction`](/reference/mcp/tools/#propose_correction) | Pin, exclude, or add guidance to future briefings |
| [`ask_question`](/reference/mcp/tools/#ask_question) | File a question, routed to whoever stewards the closest node |
| [`run_workflow`](/reference/mcp/tools/#run_workflow) | Start a run of an active workflow |
| [`apply_lens_action`](/reference/mcp/tools/#apply_lens_action) | Run one declarative action offered on a rendered lens item — the widget's own write path |
| [`render_lens`](/reference/mcp/tools/#render_lens) | Run a named saved view (board, table, lineage tree) |
| [`render_program`](/reference/mcp/tools/#render_program) | Progress and gating tree for a workstream root |
| [`hello_mcp_app`](/reference/mcp/tools/#hello_mcp_app) | Debug-only: render a minimal hello-world widget to check host support |
| [`claim`](/reference/mcp/tools/#claim) | Take the heartbeat-renewed lease on a node so no one duplicates it |
| [`renew`](/reference/mcp/tools/#renew) | Bump your live lease's expiry — the heartbeat that keeps a claim |
| [`extend`](/reference/mcp/tools/#extend) | Manually stretch your lease for a known long idle gap |
| [`reserve`](/reference/mcp/tools/#reserve) | Convert a live claim into a resumption reservation when a session ends unfinished |
| [`release`](/reference/mcp/tools/#release) | Drop the lease and return the node to the pool |

## Protocol details

The server speaks MCP over Streamable HTTP at `/mcp`, with the standard
OAuth 2.1 discovery chain a connector host expects: protected-resource
metadata (RFC 9728, advertised on the first unauthenticated request),
authorization-server metadata (RFC 8414), dynamic client registration
(RFC 7591), and authorization-code + PKCE. In practice this means you give
your host one URL and it works out the rest. The credentials a host ends up
holding — and how to revoke them — are described in
[Tokens and access](/hosted/tokens-and-access/).

## In this section

Connector setup — adding Spor in claude.ai or Claude Code and the OAuth flow
you'll see — lives in [Connect an assistant](/start-here/connect-an-assistant/).

- [The operating loop](/reference/mcp/operating-loop/) — the ORIENT → TRAVERSE → COMMIT
  mental model the server teaches connected assistants.
- [Tool reference](/reference/mcp/tools/) — every tool: purpose, key parameters, when
  to reach for it.
- [The widget](/reference/mcp/widget/) — the interactive queue, lens, and program views
  on hosts that support embedded apps.
