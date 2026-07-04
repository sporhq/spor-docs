---
title: Capture and ingestion
description: Raw text in, typed nodes out — the low-friction write path and its durability rule.
sidebar:
  order: 2
---

Most durable knowledge is discovered mid-task, at exactly the moment nobody
wants to stop and file a ticket. Capture is Spor's answer: one call with two
or three sentences, and the server does the structuring.

```json
{
  "text": "While wiring the carrier webhooks I noticed the signature check
           is duplicated across three handlers. Out of scope now — the
           rollout is Friday — but it should be extracted.",
  "during": "task-carrier-rollout"
}
```

The caller keeps working. The server drafts a typed node (here, probably an
open `task` with `derived-from → task-carrier-rollout` as provenance),
validates it against the live schema registry, stamps attribution, and
commits. If the deferral rationale is itself load-bearing ("because the
rollout is Friday"), the ingester can emit a decision node alongside, edged
to the task.

In an agent session the door is the `capture` MCP tool or `/spor:defer`;
from the shell it is `spor add "<text>"`; over REST it is `POST /v1/capture`.

## The LLM proposes; deterministic code disposes

Ingestion runs a small server-side model with the live schema registry and
the node index in its prompt: pick the schema this text instantiates, draft
the node, prefer edges to existing nodes over creating duplicates. Then the
deterministic half takes over — schema `validate()` hooks, edge
normalization, attribution stamping, the serialized commit. A draft that
fails validation bounces back to the model once for self-correction before
surfacing to the caller. Non-determinism is confined to drafting; everything
that gates or transitions a node is reviewable deterministic code.

## The data-minimization line

The capture ingestion model only ever sees the short distilled prose a
client chose to send — never a transcript. Session transcripts stay on the
client; what crosses the wire is the two-to-four sentences the client
already decided were worth keeping. This is a design line, not an
optimization: the server-side model's entire view of your session is the
capture text itself.

## Failures never lose text

If the text fits no schema well, the ingester does not force it: the raw
text is preserved as a `capture-pending` node (`cap-` prefix) and surfaces
in the decision queue for human triage. The same fallback catches drafts
that remain invalid after the self-correction bounce. A pending capture is
closed only as `merged` (its content now lives in proper nodes) or
`rejected` (no durable fact) — the type's transition gate refuses anything
else, so captured text cannot be quietly discarded.

Only a transport-level failure (the ingestion model unreachable) is an
error, and clients spool captures to an outbox and retry, carrying an
idempotency key so a timeout that actually landed server-side is not
double-written on replay.

:::tip
A capture whose text references the node named in `during` usually becomes
an elaboration appended to that node rather than a new node. For a
standalone deferred item, write text that stands alone.
:::

## When the graph cannot answer

Capture records what you learned. When you instead need something a teammate
would know, file a question so it routes to them instead of evaporating. See
[Ask and answer questions](/use-spor/ask-and-answer-questions/).
