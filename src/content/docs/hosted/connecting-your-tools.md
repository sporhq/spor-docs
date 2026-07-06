---
title: Connecting your tools
description: Point the CLI at api.sporhq.io, add the claude.ai connector, and get a teammate productive on day one.
sidebar:
  order: 3
---

Everything a client does against hosted Spor goes through `api.sporhq.io`
(REST, for the CLI and mechanical writers) or `mcp.sporhq.io` (MCP, for AI
hosts like claude.ai). Connecting a tool means giving it a credential and one
of those two addresses.

## The CLI

Getting a credential onto a machine — `spor join` with a pasted invite token,
or an interactive `spor auth login` — and confirming it with `spor whoami` is
covered step by step in
[I was invited to hosted Spor](/start-here/invited-to-hosted-spor/#2-join-with-your-invite-token).
This section covers what carries across every machine and organization you
connect, rather than that first walkthrough.

Under the hood, both paths write the client configuration as three
environment variables, which you can also set directly (CI does):

```sh
SPOR_SERVER=https://api.sporhq.io      # where the graph lives
SPOR_TOKEN=spor_pat_...                # your credential
SPOR_ORG=tidefall                      # which stored credential is active
```

Credentials are keyed by `(server, org)`, so joining a second organization
adds a credential rather than overwriting the first, and `SPOR_ORG` (or
`spor whoami --all`) tells you which one is active. See
[Organizations and sign-in](/hosted/organizations-and-sign-in/) for switching
between them, and [Configuration](/reference/configuration/) for the full
cascade these variables sit in.

One thing that surprises people: setting `SPOR_SERVER` globally does not make
every repository on your machine start writing to the team graph. Spor is
opt-in per repository — a repo participates only once it is explicitly
enabled (`spor enable`), so a side project never distills into the team's
graph by accident.

## The claude.ai connector

Add `mcp.sporhq.io` as a connector in claude.ai (or any MCP host that speaks
Streamable HTTP). The host walks you through an OAuth authorization against
`auth.sporhq.io`; the resulting grant is tied to your identity, so everything
the assistant writes through the connector is attributed to you. Tool-level
detail — what each MCP tool does and the interactive queue and lens views —
is in the [MCP section](/reference/mcp/).

## Check it worked

For the CLI, run:

```sh
spor status
```

Expect `health: OK` with a node count and an `identity:` line naming you. The
full expected output, the per-repo `(not enabled here …)` note, and what each
failure (`AUTH FAILED`, `OFFLINE`, a hang) means are walked through in
[I was invited to hosted Spor](/start-here/invited-to-hosted-spor/#check-it-worked).

For the connector, ask the assistant for your Spor queue and expect a tool
call that returns ranked items. The step-by-step check is in
[Connect an assistant](/start-here/connect-an-assistant/#4-check-it-worked).

Next step: use the teammate first-day pointer below when you are setting up
someone else.

## A teammate's first day

Setting someone else up? Point them at
[I was invited to hosted Spor](/start-here/invited-to-hosted-spor/) — it is
the full walkthrough: join or sign in, verify identity, make a first capture,
and enable a repo. The one thing that has to happen on your side first is the
**invitation** — a team admin invites them, so they have something to sign in
to.

Optionally, they can also add the connector; see
[Connect an assistant](/start-here/connect-an-assistant/). After that there
is no other hosted-specific step — the [Start here](/start-here/) material
applies as written.

What the server can see once repos are enabled and the connector is added —
and how all of it can be exported — is stated in
[Data, privacy, and export](/hosted/data-privacy-and-export/).
