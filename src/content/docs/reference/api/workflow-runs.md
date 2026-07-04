---
title: Workflow runs
description: Start runs of active workflows and drive their steps with the claim/complete worker API.
sidebar:
  order: 8
---

The run engine's claim/complete API. A worker is anything with a token: it
polls for claimable steps, claims one under a lease, does the work, and
reports a verdict. The server never executes effects itself.

## POST /v1/workflows/{id}/run

Start a run of an **active** workflow (a proposed workflow must first be
activated by a different identity than its author — the self-approval ban):

```bash
curl -s https://api.sporhq.io/v1/workflows/wf-tidefall-release-checklist/run \
  -H "Authorization: Bearer $SPOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"inputs": {"version": "2-4-0"}}'
```

Returns `{run_id, revision, workflow, workflow_version, state}`. The run is
recorded as a node with lineage; starting the run does not execute anything —
workers then claim ready steps below.

## GET /v1/work

Claimable steps across live runs, filtered by capability:

```
GET /v1/work?capability=a,b
```

Returns `{work, count, generated_at}`. Approval steps are excluded — they
surface in the decision queue for humans, not as worker-claimable work.

## POST /v1/runs/{id}/steps/{sid}/claim

Claim a ready step. Body: `{"iteration"?: N}`. Returns `{run_id, step, lease,
state}`. A step that isn't claimable is `409`.

## POST /v1/runs/{id}/steps/{sid}/complete

Report a verdict:

```json
{ "lease": "...", "status": "succeeded", "result": {...}, "log": "..." }
```

`status` must be `succeeded` or `failed` — anything else is `422`. An
expired or superseded lease is `409 lease_expired`. A same-generation retry
that disagrees with the recorded outcome is `409 outcome_conflict`: redo the
work under a fresh lease. `iteration` is accepted as in the claim.

## GET /v1/runs/{id}

The full run record: `{run_id, status, project, title, initiator, workflow,
workflow_version, lineage, state, revision, timestamps?}`.
