---
title: Local and remote mode
description: One graph model, two deployment shapes — files on your machine or a shared server — and the configuration cascade that selects between them.
sidebar:
  order: 5
---

**Use this when** you are deciding where a graph should live, moving from a
personal graph to a team server, or working out which configuration layer
wins on a machine.

**You do not need this if** you followed a quickstart and `spor status`
already shows the mode you expect; the quickstarts under [Start
here](/start-here/) cover setup.

Spor runs in two modes with the same CLI, the same node format, and the same
graph semantics. The difference is who holds the graph and who performs
writes.

## Local mode

The graph lives on your machine, outside any code repository, at `~/.spor/`
(or wherever `$SPOR_HOME` points): one markdown file per node in `nodes/`,
briefing history in `history/`, and the whole home is a plain git
repository. The client writes node files directly, ingestion for captures
runs through your locally configured model backend, and history, diffs, and
branches are just git.

Local mode is a good fit when you are trying Spor out, want personal memory
across projects, or want everything to stay on your machine. Because the
graph is outside the code repo, context distilled on a branch survives even
if the branch never merges.

A team can share a local-mode graph over plain git with no server: commit a
`.spor` marker in the code repo pointing at a sibling graph repository
(`graph: ../parcel-graph`), and everyone clones both side by side. Distilled
nodes go through your normal pull-request flow. This is simpler than remote
mode but gives up live concurrent writes, question routing, and hosted
isolation.

## Remote mode

Two environment variables switch a client to remote mode:

```bash
export SPOR_SERVER=https://api.sporhq.io
export SPOR_TOKEN=spor_pat_...
```

(`spor join <token>` writes both; `SPOR_ORG` selects among stored
credentials when you belong to several organizations.)

In remote mode the Spor server is the graph. Clients stop writing node
files entirely: every mutation goes through the server, which validates it
against the live schema registry, runs the sandboxed schema gates, stamps
attribution from the authenticated token, serializes concurrent writes, and
commits. Capture ingestion also moves server-side — the server runs the
ingestion model, and clients no longer need to know the current schemas at
all. Remote mode is what enables the team features: attributed writes,
question routing, per-person queues, claims, and shared briefings.

Updates are conflict-checked: a client sends back the revision it read, and
a mismatch is a conflict to re-read and retry — no silent last-write-wins.

## Fail open, never block

If the team server is unreachable, hooks behave as if the graph is empty and
your coding session continues; captures spool to a local outbox and drain
later (`spor drain`). A missing briefing costs context, never the session.
`spor-hook doctor` reports mode, reachability, token validity, and outbox
depth when something feels off.

## The configuration cascade

Spor reads configuration from several layers; more specific wins:

1. CLI flags
2. Environment variables (`SPOR_SERVER`, `SPOR_TOKEN`, `SPOR_ORG`,
   `SPOR_HOME`, ...)
3. Repo config: `.spor.json` in the repository
4. User config: `$SPOR_HOME/config.json`
5. Global config: `~/.config/spor/config.json`
6. Built-in defaults

One deliberate exception: a committed `.spor` marker's `graph:` binding
overrides `SPOR_HOME` in local mode, so a contributor with a personal global
graph still inherits the shared graph inside a shared-graph repo.

Never commit a team token into `.spor.json`; keep secrets in the
environment, user config, or global config.

## Per-repo opt-in

Installing Spor does not enable it everywhere. A repo is inactive — hooks
are a complete no-op, nothing is injected or distilled — until it opts in
with a `.spor` or `.spor.json` marker (`spor enable` writes one) or an
explicit `enabled` flag in the cascade. An explicit `enabled: false` wins
over a marker. The default is off even in remote mode: a globally configured
`SPOR_SERVER` selects the mode but does not by itself enable an unrelated
repo, so a side project never leaks context into the team graph by
accident.

`spor status` shows the resolved mode, graph, identity, and whether the
current repo is active.
