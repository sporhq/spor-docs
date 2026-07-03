---
title: Your data
description: Full export at any time, exactly what the ingestion model sees, and how custom code is contained.
sidebar:
  order: 7
---

Hosting your team's graph should not mean surrendering it, and it should not
mean a model reading more of your work than you chose to send. This page
states what hosted Spor does with your data — precisely, because the claims
are only useful at their exact scope.

## Export: a full data exit, any time

`GET /v1/export` returns your organization's complete node set as a tarball
(add `?gzip=1` to compress); piping it through `tar x` reproduces the
`nodes/` directory byte for byte. The history option (`?history=1`) goes
further and streams a complete git bundle of the graph's revision history —
every commit, not just the current state — which `git clone` turns back into
a working graph repository.

```bash
spor export --gzip --out graph.tar.gz    # the current node set
spor export --history --out graph.bundle # the full revision history
```

That bundle is a full data exit: everything the hosted graph knows, in a
format you can carry to a local graph or a self-hosted server. It is
available at any time, to any member with a valid token, not as an
offboarding concession.

## What the ingestion model sees

One path in hosted Spor involves a language model on the server: capture
ingestion, where free text you send is turned into typed nodes. The scope of
what that model sees is deliberately narrow: **the capture ingestion model
sees only the short distilled prose a client chose to send — never a
transcript.** Your session with your own coding agent is not shipped to the
server; the client distills a few standalone sentences and sends those.

Before that model sees anything at all, deterministic secret and PII
redaction runs over the submitted text. Redaction is not a model judgment
call — it happens first, mechanically.

Note the boundaries of this claim: it is about the capture ingestion model,
stated exactly. The graph itself — the nodes your team writes — is of course
stored and served by the Spor server; that is what it is for.

## Custom code runs in a sandbox

Teams can attach custom schema and lens code to graph nodes — validation
rules, computed views. On the server that code runs in a locked-down sandbox
with no network, no clock, and no filesystem access, so a team's custom
validation logic cannot reach other tenants, the host, or anything beyond the
graph data it was handed. A misbehaving lens is a broken lens, not an
incident.

## Keeping the graph healthy

Two operational surfaces round this out:

- **The gardener** is an automated hygiene sweep any authenticated member can
  run (`POST /v1/gardener`). It files what it finds as items in the decision
  queue and resolves its own findings once they are cleared — so graph
  hygiene is visible work, not silent mutation.
- **`GET /v1/status`** reports service health and basic operational metrics
  for your organization's graph, and doubles as the health check when you are
  diagnosing slowness beyond an ordinary [wake](/hosted/wake-on-request/).
