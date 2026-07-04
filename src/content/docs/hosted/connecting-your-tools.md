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

The interactive path is `spor auth login`. It uses a device flow, so it works
on a headless box or over SSH: the CLI prints a URL and a short code, you
approve in any browser (signing in at the hosted front door if you aren't
already), and the CLI receives an org-scoped credential and stores it. When a
browser is available on the same machine, `spor auth login --web` skips the
code and completes through a local redirect instead.

If you were handed a token directly — the invitation path — paste it with
`spor join`:

```sh
spor join spor_pat_...                 # hosted Spor; api.sporhq.io is the default
spor join https://spor.example.com spor_pat_...   # a self-hosted server instead
```

Both paths write the client configuration for you. Under the hood it is three
environment variables, which you can also set directly (CI does):

```sh
SPOR_SERVER=https://api.sporhq.io      # where the graph lives
SPOR_TOKEN=spor_pat_...                # your credential
SPOR_ORG=tidefall                      # which stored credential is active
```

Verify with `spor whoami` (or `GET /v1/me`): it echoes the person your token
is bound to — name, person node id, and email. To confirm which organization
is active, run `spor whoami --all`, which lists the stored identity for every
organization; in the API, `GET /v1/me` reports the org directly.

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

A healthy connection looks like:

```text
mode:     remote
project:  billing
server:   https://api.sporhq.io
health:   OK (214 nodes)
token:    present
identity: Ines Duarte (person-ines) <ines@tidefall.example.com>
node:     20.11.0 (>= 20 required, OK)
```

In a repository that has not run `spor enable`, the `mode:` line carries a
`(not enabled here …)` note. That is the per-repo opt-in this page already
describes, not a connection failure.

- If you see `health:   AUTH FAILED (401) — token invalid, revoked, or expired`,
  re-run `spor auth login`, or paste a fresh token with `spor join`.
- If you see `health:   OFFLINE — could not reach server (fetch failed)`, the
  server URL is wrong or there is no network.
- If `identity:` shows
  `⚠ token maps to no person node — routed questions and personal queue will be empty`,
  the identity binding is missing; an admin fixes it. This is the same
  `bound: false` condition described below.
- If this hangs, the graph may be waking from idle; wait rather than retrying.
  See
  [slow first request diagnostics](/reference/diagnostics/#slow-first-request-after-an-idle-period).

For the connector, ask the assistant for your Spor queue and expect a tool
call that returns ranked items. The step-by-step check is in
[Connect an assistant](/start-here/connect-an-assistant/#4-check-it-worked).

Next step: use the teammate first-day list below when you are setting up
someone else.

## A teammate's first day

What a new teammate actually needs:

1. **An invitation** from an admin, and a sign-in at the hosted front door.
2. **The CLI connected** — `spor auth login`, then `spor whoami` to confirm
   the token is bound to their person node (a warning that the token maps to
   no person node — `bound: false` in `GET /v1/me` — means the identity
   binding is missing; the admin fixes that).
3. **Their working repos enabled** — `spor enable` in each repo that should
   participate in the graph.
4. **Optionally, the connector** — add `mcp.sporhq.io` in claude.ai.

After that there is no hosted-specific workflow to learn; the
[Start here](/start-here/) material applies as written.

What the server can see once repos are enabled and the connector is added —
and how all of it can be exported — is stated in
[Data, privacy, and export](/hosted/data-privacy-and-export/).
