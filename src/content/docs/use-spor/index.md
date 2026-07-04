---
title: Use Spor
description: Work with Spor day to day after the CLI is installed and a graph exists.
sidebar:
  order: 1
---

Use Spor when project history should affect the next working session. The
everyday loop is small: record useful work when it appears, read the queue
when choosing what to do next, start sessions from a briefing, and correct the
graph when its memory is wrong.

The graph is made of entries, called nodes, and typed links between them,
called edges. A node records one durable fact: a decision, task, issue,
question, or norm. The links say how those facts relate —
[Core ideas](/start-here/core-ideas/) explains the model. That structure lets
Spor rank open work, compile relevant context for an agent, and attribute
writes to the person or agent that made them.

## In this section

- [Capture, ingestion, and questions](/use-spor/capture/) — record useful work
  the moment it appears. `spor add "<two or three sentences>"`, or the MCP
  `capture` tool, turns raw prose into a typed, linked node.
  `spor ask "<question>"` files a question the graph cannot answer; in remote
  mode it routes to the person most likely to know.
- [The decision queue](/use-spor/queue/) — `spor next`, or the `show_queue` MCP
  tool, returns open work ranked by graph signals and human-set priority, with
  a one-line reason for each item.
- [Briefings and corrections](/use-spor/briefings/) — read the context packet
  an agent receives at session start, including decisions in force, rejected
  approaches, and open blockers. Use `spor correct` for standing corrections
  when a briefing is wrong or stale.
- [Identity and attribution](/use-spor/identity/) — see how every write is
  attributed to a person, or to an agent writing on behalf of the person who
  owns it.
- [Dispatch, capabilities, and profiles](/use-spor/dispatch/) — use
  `spor dispatch <node-id>` to compile a briefing and launch a background
  agent against a queue item, pre-briefed instead of cold.
- [What happens automatically](/use-spor/what-happens-automatically/) — wire
  Spor into a coding agent, then the four session hooks that run for you:
  the session-start briefing, per-prompt digest, commit linking, and the
  end-of-session distiller — all fail-open.
