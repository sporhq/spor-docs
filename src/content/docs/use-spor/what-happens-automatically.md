---
title: What happens automatically
description: The session hooks the plugin runs — briefing injection, per-prompt digests, commit linking, and the end-of-session distiller.
sidebar:
  order: 9
---

Spor can brief a coding session automatically once a host is wired and the
repository is enabled. The plugin does its work through four hooks in the
session. In Claude Code these attach to the host's native hook points; the
other supported hosts receive equivalent hooks from the same manifest.

## Wire a host

`spor install` connects Spor to an agent host so sessions get briefed
automatically. Supported hosts are `claude`, `codex`, `gemini`, `opencode`,
`copilot`, and `cursor`.

```bash
spor install claude
```

With no host named, it lists what it detects on your machine and changes
nothing:

```bash
spor install            # detect only
spor install --all      # install into every detected host
spor install --print    # dry run: show what would change
```

Re-running `spor install` is safe. It refreshes paths and does not duplicate
hooks.

Hooks act only in repositories enabled with `spor enable`.

A new npm release does not change what a host has already loaded. Upgrade the
package with `npm install -g @sporhq/spor`, then run `spor upgrade`. The full
flags for `spor install` and `spor upgrade`, including `--scope`, are in
[Setup and identity](/reference/cli/setup-and-identity/).

### Check it worked

Run:

```sh
spor status
```

A wired host adds a plugin line:

```text
plugin:   spor@spor 0.18.6 loaded
```

The end-to-end check is behavioral: start a new session in an enabled
repository, and the briefing described below appears as injected context at
session start.

- If there is no `plugin:` line, the host is not wired; re-run
  `spor install claude` and restart the host so it reloads.
- If the line says `(STALE — package … installed; run 'spor upgrade')`, the
  host loaded an older copy; run `spor upgrade`.
- If sessions start with no briefing, the repository is probably not enabled;
  run `spor enable` there and check `spor status` in that directory.
- If hooks were working and stopped, `spor-hook doctor` reports recent hook
  and distiller errors, as described in
  [Everything fails open](#everything-fails-open).

Next step: start a session and check for the briefing described below.

## At session start: the briefing

When a session starts (or resumes) in an enabled repo, Spor compiles a
briefing from the graph — the decisions that still apply, rejected
approaches, open tasks and blockers, project conventions, and standing
corrections — and injects it as context. The agent starts already knowing,
for example, that `dec-tidefall-billing-retries` settled the retry schedule
and that the open blocker is `issue-tidefall-double-charge`, instead of
rediscovering both.

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
