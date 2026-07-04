---
title: Costs and controls
description: Where Spor makes model calls, how to see what they cost, and how to disable pieces or supply your own backend.
---

The client makes small model calls for exactly two things:

- **distilling** — turning the useful parts of a finished session into one or
  two graph nodes;
- **nudging** — suggesting, mid-session, that a discovery is worth capturing
  before it vanishes.

Nothing else on the client calls a model. Briefings and digests are compiled
from the graph, not generated. (In remote mode the server also runs an
ingestion model to type and link captures; that cost sits with whoever
operates the server, not with your client.)

## Seeing what it costs

Every model call the client makes is journaled locally, under
`$SPOR_HOME/journal/llm-calls/`. Summarize spend with:

```bash
spor cost
spor cost --since 2026-06-01
spor cost --project harbor --json
```

`--since`/`--until` bound the date range, `--project` scopes to one project,
and `--json` emits machine-readable output.

## Turning pieces off

Both callers can be disabled independently, via the environment:

```bash
export SPOR_DISTILL=0   # no end-of-session distillation
export SPOR_NUDGE=0     # no mid-session capture suggestions
```

With both off, Spor makes no model calls at all from your machine: briefings,
digests, the queue, and manual `spor add` continue to work, because none of
them require one. What you lose is the automatic write-back — you would
record outcomes yourself with `spor add`.

## Supplying your own backend

Instead of disabling a piece, you can point it at any command you control:

```bash
export SPOR_DISTILL_CMD=/usr/local/bin/my-distiller
export SPOR_NUDGE_CMD=/usr/local/bin/my-classifier
```

The contract is deliberately small: the prompt arrives on stdin, the response
is read from stdout. That is enough to route the calls through a local model,
a different provider, or a proxy that enforces your own budget and logging.
