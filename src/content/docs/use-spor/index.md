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

- [Capture and ingestion](/use-spor/capture/) — record useful work
  the moment it appears. `spor add "<two or three sentences>"`, or the MCP
  `capture` tool, turns raw prose into a typed, linked node.
- [Ask and answer questions](/use-spor/ask-and-answer-questions/) —
  `spor ask "Did the dunning email copy get updated for the three-attempt retry window?"` files a question the graph cannot answer. In remote
  mode it routes to the steward most likely to know, and an `answers` edge from
  the eventual answer closes it.
- [The decision queue](/use-spor/queue/) — `spor next`, or the `show_queue` MCP
  tool, returns open work ranked by graph signals and human-set priority, with
  a one-line reason for each item.
- [Briefings and corrections](/use-spor/briefings/) — read the context packet
  an agent receives at session start, including decisions in force, rejected
  approaches, and open blockers. Use `spor correct` for standing corrections
  when a briefing is wrong or stale.
- [Review what changed](/use-spor/review-what-changed/) — catch up with
  `spor changes`, follow one node's editors with `spor history`, trace a
  commit to its reasons with `spor blame`, and read a program view for a whole
  workstream.
- [Identity and attribution](/use-spor/identity/) — see how every write is
  attributed to a person, or to an agent writing on behalf of the person who
  owns it.
- [What happens automatically](/use-spor/what-happens-automatically/) — wire
  Spor into a coding agent, then the four session hooks that run for you:
  the session-start briefing, per-prompt digest, commit linking, and the
  end-of-session distiller — all fail-open.

Running work as background agents — `spor dispatch`, capability maps, and
profiles — is reference material:
[Dispatch, capabilities, and profiles](/reference/dispatch/).
