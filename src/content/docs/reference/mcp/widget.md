---
title: The widget
description: The interactive queue, lens, and program views on MCP-Apps-capable hosts — and the text fallback everywhere else.
sidebar:
  order: 4
---

<!-- view-carrying-tools:start -->
[`explore_graph`](/reference/mcp/tools/#explore_graph),
[`render_queue`](/reference/mcp/tools/#render_queue),
[`render_lens`](/reference/mcp/tools/#render_lens), and
[`render_program`](/reference/mcp/tools/#render_program) attach an interactive view
to their result. On a host that supports MCP Apps (Claude, Goose, VS Code),
the result renders as an embedded widget in the conversation instead of a
wall of text: one trusted interpreter of Spor's view catalog, covering
boards, tables, lists, and trees.
<!-- view-carrying-tools:end -->

One more tool, [`hello_mcp_app`](/reference/mcp/tools/#hello_mcp_app), also
mounts a widget on an MCP-Apps host, but it sits outside this catalog: a
bare connectivity probe for debugging whether a host can mount a Spor app
resource at all, not a rendering of graph data.

What you get in the widget:

- **Status chips** on queue and board items, and **progress bars** on a
  program view — where the workstream stands at a glance.
- **Lineage trees** — why a node exists and what it depends on, expandable
  in place.
- **Node detail on click.** Selecting an item fetches the node directly from
  the server, with no model round-trip — browsing the queue costs no
  conversation turns.
- **Conversational affordances** on queue items — hand an item back to the
  assistant to pick up as the next task.

## Mutations are explicit tool calls

The widget's views are read-only rendering, with one exception: a lens can
offer a declarative action on a rendered item (a status button on a board
card, say), and selecting it calls
[`apply_lens_action`](/reference/mcp/tools/#apply_lens_action) — validated
and attributed to your token exactly like any other write, not a silent
mutation of the view in place. Every other write goes through the
[write tools](/reference/mcp/tools/#writing) directly. Either way, what
changes the graph is always a tool call you can see in the conversation.

## Hosts without app support

The widget is strictly additive. A host without the MCP Apps surface ignores
the attached view and shows the same result as text — `render_program` still
returns its progress header and glyphed gating tree, `render_lens` its
rendered view, `render_queue` the ranked items, and `explore_graph` the same
neighborhood as plain nodes and edges. Nothing about the data differs; only
the presentation does. That is also why
[`show_queue`](/reference/mcp/tools/#show_queue) exists alongside `render_queue`: same
queue, but `show_queue` is the data-oriented answer for hosts (and turns)
that just need it, while `render_queue` makes widget attachment an explicit
choice.

The one thing a non-Apps host has nothing to fall back to is a lens's
declarative actions: those buttons only exist on a rendered widget, so
`apply_lens_action` has no path in without one. On such a host, every
mutation goes through the explicit [write tools](/reference/mcp/tools/#writing) instead.
