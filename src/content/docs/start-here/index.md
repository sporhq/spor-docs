---
title: Start here
description: Install Spor, wire it into your coding agent, and record your first node — locally or against a team server.
sidebar:
  order: 2
---

New to Spor? [What is Spor?](/start-here/what-is-spor/) is the
plain-language introduction; this page routes you to installation and a
quickstart.

Spor runs in two modes, with the same CLI for both:

- **Local** — your graph is a plain git repository of markdown files on your
  machine (`~/.spor` by default). No server, no database. Good for trying
  Spor out, or for personal memory across projects.
- **Remote** — your team shares one live graph on a Spor server. Writes are
  attributed to the person or agent that made them, captures are typed and
  linked by the server, and open questions can route to the person most
  likely to know.

Every command works in both modes and resolves the mode from your
configuration: with `SPOR_SERVER` set (or a stored credential from
`spor join`), commands talk to the server; otherwise they read and write the
local graph directly. `spor status` always shows which mode is active, which
graph you are on, and who you are.

## Where to start

1. [Install the CLI and wire your coding agent](/start-here/install/).
   This step is the same for both modes.
2. Pick a quickstart:
   - [Local quickstart](/start-here/local-quickstart/) — create a graph
     on your machine and record your first node. Start here if you are on
     your own or evaluating Spor.
   - [Hosted quickstart](/start-here/hosted-quickstart/) — join a team
     graph with an invite token or a browser sign-in. Start here if someone
     on your team already runs Spor.

You can move from local to remote later; the graph format and the CLI do not
change.

## Related pages

- [What happens automatically](/start-here/what-happens-automatically/)
  — what the plugin does in each coding session once a repo is enabled:
  briefings, digests, commit linking, and the end-of-session distiller.
- [What Spor is not](/start-here/what-spor-is-not/) — the product's
  boundaries: six things Spor does not try to be, and where to go if you
  wanted one of them.
- [Costs and controls](/reference/costs-and-controls/) — where Spor
  makes model calls, how to see what they cost, and how to turn them off or
  point them at your own backend.
- [Diagnostics](/reference/diagnostics/) — `spor status`,
  `spor-hook doctor`, and what happens to captures when the server is
  unreachable.
