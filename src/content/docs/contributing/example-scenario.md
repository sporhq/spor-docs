---
title: The tidefall scenario
description: The one fictional running example every docs page draws its examples from — the cast, the node ids, and the story arc.
sidebar:
  order: 4
---

Spor docs use one **running example** so examples across pages read as one
coherent story. A reader who meets tidefall on one page recognizes it on the
next, and the [example data rules](/contributing/style-guide/#example-data)
stay easy to audit. Nothing in this scenario comes from a real graph.

## The team

The team is tidefall, a small fictional SaaS company with subscription
billing. Its organization node is `org-tidefall`, and its email domain is
`tidefall.example.com`. The billing service lives in `repo-billing`, whose
slug is `billing`; that repo is grouped under `proj-tidefall`. Ines Duarte is
the billing lead. She stewards the billing area and
`spec-tidefall-dunning-flow`, and her email is
`ines@tidefall.example.com`. Marek Ilves joins the team later and carries the
retry-flow rework; his email is `marek@tidefall.example.com`.
`agent-ines-laptop` is Ines's laptop dispatch agent and is owned by
`person-ines`.

Identity ids: `person-ines`, `person-marek`, `org-tidefall`,
`repo-billing`, `proj-tidefall`, `agent-ines-laptop`.

## The story

1. In 2025, tidefall records `dec-tidefall-retry-once`: a **decision** that
   a failed card charge is retried once, immediately. Later work supersedes
   this decision.
2. Retry-once recovers too few charges, and paying customers churn after one
   transient card failure. Marek joins the team and picks up the rework. His
   briefing surfaces `dec-tidefall-retry-once` and its rationale, so he does
   not repeat the old debate.
3. The team records `dec-tidefall-billing-retries`, an active **decision**
   for the `billing` project dated `2026-06-12`: failed card charges retry
   three times over two days, then a dunning email asks the customer to
   update billing details. A longer retry window is rejected because it
   delays that email past the next billing cycle. The decision carries
   `supersedes` to `dec-tidefall-retry-once` and `derived-from` to
   `spec-tidefall-dunning-flow`.
4. The rollout is grouped under `task-tidefall-retry-rollout`, a **program**.
   The member task `task-tidefall-retry-emails` updates the dunning emails
   for the three-attempt window and carries a `blocks` edge to the umbrella.
   This is the queue item the story claims, briefs, and works.
5. Mid-rollout, the team finds `issue-tidefall-double-charge`: a retry that
   succeeds while the payment provider's webhook is delayed can charge the
   card twice. The issue blocks the rollout. The decision
   `dec-tidefall-idempotency-keys` resolves it: every charge attempt carries
   an idempotency key, so the provider deduplicates replays. That decision
   carries a `resolves` edge to `issue-tidefall-double-charge`.
6. Marek files `question-tidefall-dunning-copy`: "Did the dunning email copy
   get updated for the three-attempt retry window?" The open question routes
   to Ines, the steward. She answers with `art-tidefall-dunning-copy`, which
   carries an `answers` edge back to the question.
7. Briefings for `task-tidefall-retry-emails` keep surfacing
   `dec-tidefall-legacy-invoicing`, a stale decision from an invoicing system
   that was since rewritten. The standing **correction**
   `corr-task-tidefall-retry-emails-1` targets
   `task-tidefall-retry-emails`, pins `spec-tidefall-dunning-flow`, and
   excludes `dec-tidefall-legacy-invoicing`.
8. The team records `norm-tidefall-reversible-migrations`: a **norm** that
   migrations on billing tables must be reversible.
9. tidefall's own CLI reference page for `retryctl retry` is anchored to the
   command's implementation: `art-tidefall-doc-retryctl-cli` carries a
   `derived-from` edge to `art-tidefall-anchor-retryctl-js`, a provenance
   anchor recording `path: bin/retryctl.js` and its blob `sha` at anchoring
   time. If `bin/retryctl.js` changes without a matching anchor re-stamp, the
   gardener's drift sweep files a finding against the anchor.

## Node id registry

| id | type | role in the story |
| --- | --- | --- |
| `org-tidefall` | organization | The fictional tidefall organization. |
| `person-ines` | person | Ines Duarte, billing lead and steward for the billing area and dunning-flow spec. |
| `person-marek` | person | Marek Ilves, the engineer who joins later and carries the retry-flow rework. |
| `agent-ines-laptop` | agent | Ines's laptop dispatch agent, owned by `person-ines`. |
| `proj-tidefall` | project | The project grouping tidefall's billing work. |
| `repo-billing` | repo | The billing service repo, with slug `billing`, grouped under `proj-tidefall`. |
| `spec-tidefall-dunning-flow` | artifact (`spec-`) | The dunning-flow spec for the retry schedule and email sequence, stewarded by Ines. |
| `dec-tidefall-retry-once` | decision | The 2025 launch decision to retry a failed card charge once, immediately. |
| `dec-tidefall-billing-retries` | decision | The active decision to retry failed card charges three times over two days before the update-billing email. |
| `task-tidefall-retry-rollout` | task | The umbrella program for the retry rollout. |
| `task-tidefall-retry-emails` | task | The member task to update dunning emails for the three-attempt window. |
| `issue-tidefall-double-charge` | issue | The rollout blocker where a delayed provider webhook can allow a successful retry to double-charge. |
| `dec-tidefall-idempotency-keys` | decision | The decision that resolves the double-charge issue by requiring an idempotency key on every charge attempt. |
| `question-tidefall-dunning-copy` | question | Marek's question about whether the dunning email copy was updated for the three-attempt retry window. |
| `art-tidefall-dunning-copy` | artifact | Ines's answer to the dunning-copy question. |
| `dec-tidefall-legacy-invoicing` | decision | A stale legacy invoicing decision that corrections exclude from retry-email briefings. |
| `corr-task-tidefall-retry-emails-1` | correction | The standing correction that pins the dunning-flow spec and excludes the legacy invoicing decision. |
| `norm-tidefall-reversible-migrations` | norm | The team convention that billing-table migrations must be reversible. |
| `lens-tidefall-retry-radar` | lens | A saved board view of open work gating the retry rollout. |
| `wf-tidefall-release-checklist` | workflow | A release-checklist workflow used elsewhere in the docs. |
| `schema-provider-escalation` | schema | A custom node type for provider-facing escalations with a required severity field. |
| `art-tidefall-anchor-retryctl-js` | artifact | Provenance anchor for `bin/retryctl.js`, the source `retryctl retry`'s reference page documents. |
| `art-tidefall-doc-retryctl-cli` | artifact | The CLI reference page for `retryctl retry`, anchored to its implementation via `derived-from`. |

## Using the scenario

- Draw the scene that fits the page's object. Quote the relevant beat instead
  of retelling the whole arc.
- Keep the facts stable: failed card charges retry three times over two days,
  then the dunning email asks the customer to update billing details. The
  longer retry window was rejected because it delays that email past the next
  billing cycle.
- When a page needs an object the scenario lacks, extend this page in the
  same PR rather than inventing a disconnected example.
- Secrets, tokens, and hostnames follow the
  [style guide](/contributing/style-guide/#example-data).
