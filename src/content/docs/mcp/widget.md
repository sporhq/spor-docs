---
title: The widget
description: The interactive queue, lens, and program views on MCP-Apps-capable hosts — and the text fallback everywhere else.
sidebar:
  order: 5
---

Three tools — [`render_queue`](/mcp/tools/#render_queue),
[`render_lens`](/mcp/tools/#render_lens), and
[`render_program`](/mcp/tools/#render_program) — attach an interactive view
to their result. On a host that supports MCP Apps (Claude, Goose, VS Code),
the result renders as an embedded widget in the conversation instead of a
wall of text: one trusted interpreter of Spor's view catalog, covering
boards, tables, lists, and trees.

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

## Read-only by design

The widget never writes. It emits no write-path actions; every mutation goes
through the [write tools](/mcp/tools/#writing), where it is validated,
schema-gated, and attributed to your token. What you see in the widget is a
view; what changes the graph is always a tool call you can see in the
conversation.

## Hosts without app support

The widget is strictly additive. A host without the MCP Apps surface ignores
the attached view and shows the same result as text — `render_program` still
returns its progress header and glyphed gating tree, `render_lens` its
rendered view, `render_queue` the ranked items. Nothing about the data
differs; only the presentation does. That is also why
[`show_queue`](/mcp/tools/#show_queue) exists alongside `render_queue`: same
queue, but `show_queue` is the data-oriented answer for hosts (and turns)
that just need it, while `render_queue` makes widget attachment an explicit
choice.
