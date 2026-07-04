---
title: Data, privacy, and export
description: What hosted Spor can see, what reaches a model, and how export, revocation, and offboarding work.
sidebar:
  order: 6
---

This page states hosted Spor's data posture at its exact scope. It answers
what Spor can see, what a connected assistant can see, what gets sent to a
model, whether you can export everything, how access is revoked, and what
happens when you leave an organization.

## What Spor can see

Spor is opt-in per repository. A repository participates only after someone
runs `spor enable`, so a side project on the same machine does not feed the
team graph by accident.

What reaches the Spor server is what clients deliberately send: nodes
teammates write through the CLI, REST API, or MCP connector; capture text;
and references such as commit ids that link work to nodes. Those references
are what let `spor blame` answer which nodes reference a commit.

Session transcripts stay on the client: what a wired session sends is the
short capture text described under
[what gets sent to a model](#what-gets-sent-to-a-model), never the
transcript itself.

Each organization gets one graph, isolated from every other organization's
graph. An org-scoped token routes each request to your organization's graph,
so no organization sees another's data.

## What a connected assistant can see

An assistant connected through the MCP connector, such as claude.ai, holds an
OAuth grant tied to your identity. The grant has the same flat read/write
scope as your own token: it can read what you can read, which is your
organization's graph, and nothing beyond it.

Everything the assistant writes through the connector is attributed to you —
as far as attribution is concerned, the connector is you. Background agents
are different: they run under their own agent tokens, write on behalf of
their owning person, and the recent-changes feed marks their changes as
machine-authored.

See [Agents and attribution](/hosted/agents-and-attribution/) for the hosted
Spor audit trail.

## What gets sent to a model

One path in hosted Spor involves a language model on the server: capture
ingestion, where free text you send is turned into typed nodes. The scope is
deliberately narrow: **the capture ingestion model sees only the short distilled prose a client chose to send — never a transcript.**

In plain language, the client decides what to send. It sends two to four
standalone sentences it already judged worth keeping, and those sentences are
the server-side model's entire view of your session.

Before that model sees anything at all, deterministic secret and PII
redaction runs over the submitted text. Redaction is mechanical and happens
first; it is not a model judgment call.

Note the boundaries of this claim: it is about the capture ingestion model,
stated exactly. The graph itself — the nodes your team writes — is of course
stored and served by the Spor server; that is what it is for.

The client-side pieces that make model calls, including the end-of-session
distiller and the capture nudge, can be turned off or pointed at your own
backend. See [Costs and controls](/reference/costs-and-controls/) for those
settings.

## Exporting everything

`GET /v1/export` returns your organization's complete node set as a tarball.
Add `?gzip=1` to compress it; piping the result through `tar x` reproduces
the `nodes/` directory byte for byte. The `?history=1` option streams a
complete git bundle of the graph's revision history, every commit and not
just the current state, which `git clone` turns back into a working graph
repository.

```sh
spor export --gzip --out graph.tar.gz    # the current node set
spor export --history --out graph.bundle # the full revision history
```

The bundle is a full data exit: everything the hosted graph knows, in a
format you can carry to a local graph or a server of your own. It is
available at any time to any member with a valid token, not as an offboarding
concession.

## Revoking access

Revoke your own personal access tokens with
`spor token revoke <hash-prefix>`. `spor token list` shows them by hash
prefix and label; the server keeps only a hash and cannot show plaintext it
never stored.

Revoking a personal access token also revokes every OAuth grant that was
authorized with it, so killing the token kills the access, including a
connector's. Grants can also be revoked independently of your tokens.

An expired token is refused exactly like a revoked one.

Admins can list any member's tokens, seeing hash prefixes and metadata only,
and revoke any token. This is the offboarding and suspected-leak path.

Agent standing tokens are listable and revocable per agent, so one
environment's credential can be rotated without touching the owner's other
access.

See [Tokens and access](/hosted/tokens-and-access/) for token and OAuth
management.

## If you leave the organization

Offboarding is credential revocation. An admin revokes your tokens, and with
them every grant they authorized. On your side, `spor auth logout <org>`
drops a stored credential.

Credentials are org-scoped, so leaving one organization does not touch your
access to any other organization or to your own local graphs.

The graph stays with the organization, including the nodes you authored. They
remain attributed to your person node, because the graph is the team's
durable record.

Export requires a valid member token, so if you want a copy of anything you
are entitled to take, export while you are a member.

## Custom code runs in a sandbox

Teams can attach custom schema and lens code to graph nodes: validation
rules and computed views. On the server, that code runs in a locked-down
sandbox with no network, no clock, and no filesystem access, so a team's
custom validation logic cannot reach other tenants, the host, or anything
beyond the graph data it was handed. A misbehaving lens is a broken lens, not
an incident.

## Keeping the graph healthy

Two operational surfaces round this out:

- **The gardener** is an automated hygiene sweep any authenticated member can
  run (`POST /v1/gardener`). It files what it finds as items in the decision
  queue and resolves its own findings once they are cleared, so graph hygiene
  is visible work, not silent mutation.
- **`GET /v1/status`** reports service health and basic operational metrics
  for your organization's graph, and doubles as the health check when
  diagnosing slowness that outlasts a
  [slow first request](/reference/diagnostics/#slow-first-request-after-an-idle-period).
