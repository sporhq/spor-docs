---
title: What happens automatically
description: The session hooks the plugin runs — briefing injection, per-prompt digests, commit linking, and the end-of-session distiller.
sidebar:
  order: 7
---

Once a host is [wired](/start-here/install/) and a repository is enabled
(`spor enable`), you mostly stop thinking about Spor. The plugin does its
work through four hooks in the coding session. In Claude Code these attach to
the host's native hook points; the other supported hosts receive equivalent
hooks from the same manifest.

## At session start: the briefing

When a session starts (or resumes) in an enabled repo, Spor compiles a
briefing from the graph — the decisions that still apply, rejected
approaches, open tasks and blockers, project conventions, and standing
corrections — and injects it as context. The agent starts already knowing,
for example, that `dec-retry-backoff` settled the backoff policy and that the
open blocker is `issue-export-429-header`, instead of rediscovering both.

## On each prompt: a relevance digest

Each time you submit a prompt, a hook compiles a short digest of the graph
nodes most relevant to what you just asked and attaches it. This is a
per-prompt narrowing of context, sized to be cheap: a handful of related
nodes, not a second briefing.

## After edits: commit linking

After file edits and shell commands, a hook watches for resulting commits and
links them to the graph nodes they relate to. This is what lets `spor blame`
and node history answer "which decision does this commit implement?" later,
without anyone annotating commits by hand.

## At session end: the distiller

When the session ends, a distiller reviews what happened and writes the
durable outcomes back to the graph — typically one or two nodes: a decision
that got made, an approach that was rejected, a follow-up that was deferred.
It runs asynchronously, after your session has already closed, so you never
wait on it. This is the write half of the loop: the next session's briefing
is built from what this one distilled.

## Everything fails open

Every hook is designed so that a failure never breaks your session. Each runs
under a bounded timeout, and if the graph is unreachable, a token has
expired, or a hook crashes, the session continues — you get less context, not
an error. Captures that could not reach a team server are spooled and
replayed later (see [diagnostics](/reference/diagnostics/)), and
`spor-hook doctor` reports recent hook and distiller errors when you want to
know what has been failing quietly.

The distiller and the capture nudge are the two pieces that make model calls;
[costs and controls](/reference/costs-and-controls/) covers turning
them off or pointing them at your own backend.
