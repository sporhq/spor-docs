---
title: Wake-on-request
description: Your organization's graph service sleeps when idle and wakes on the first request — here is what that costs.
sidebar:
  order: 4
---

An organization's graph service does not run around the clock. When it has
been idle for a while it suspends, and the next request — whoever sends it,
CLI, web app, or connector — wakes it. You never manage this; it is worth
understanding only because of what it does to the first request's latency.

## What to expect

- **A warm wake adds roughly half a second.** This is the common case: the
  service was recently asleep and resumes quickly.
- **A cold wake can take longer — up to about a minute on a large graph.**
  The first request of the morning, or the first after a long quiet stretch,
  may sit until the graph is loaded and ready.
- **Everything after the wake runs at normal speed.** The cost is paid once
  per wake, not per request.

So if your first `spor` command of the day hangs for a moment and then
everything is instant, that is wake-on-request behaving as designed, not a
degraded service.

## How the tooling copes

The client is built to absorb this. Session hooks fail open — a slow or
unreachable graph never blocks your coding session; the session just proceeds
as if the graph had nothing for it, and the hooks catch up on later requests.
Captures are guarded against the wake-latency edge case too: a capture that
times out client-side may still complete on the server a few seconds later,
and the client sends an idempotency key with each capture so a retry cannot
record the same thing twice.

If a request seems slow beyond a wake, `GET /v1/status` reports your graph's
health and basic operational metrics — see [Your data](/hosted/your-data/).
