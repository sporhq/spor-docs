---
title: Page templates
description: The two page shapes used across the docs — how-to and concept — and what review checks against them.
sidebar:
  order: 3
---

Most docs pages use one of two shapes: a **how-to page**, when the reader
wants to complete a task, or a **concept page**, when the reader wants to
understand something. Starting from the matching template keeps a new page consistent with
its neighbors, and the PR checklist asks which template a new page follows.

## How-to pages

Use a how-to page for setup, configuration, or any page whose title is a task
the reader wants to complete.

```md
---
title: <The task, named as the reader's goal>
description: <One plain sentence.>
---

<One-sentence purpose: what the reader will have when the page is done.>

Use this when <the situation that calls for this page>.

## Before you start

## Steps

## Check it worked

## Common problems

## Related reference
```

- Opening purpose: state the outcome the reader will have, not the feature the
  page explains.
- `Use this when`: name the situation clearly so a reader can leave early when
  the page is not for them.
- `Before you start`: list prerequisites the reader can verify, such as
  versions, access, or prior pages.
- `Steps`: use a numbered sequence. Each step is one action, with the command
  the reader runs.
- `Check it worked`: include this on every setup page. Give the command to run
  and the output that indicates success, so the reader knows they are done
  before moving on.
- `Common problems`: pair each symptom the reader can see with the fix.
- `Related reference`: link the reference entries for the commands the page
  used.

## Concept pages

Use a concept page when the reader asks what something is or how it works, and
the page needs to build understanding before pointing at commands.

```md
---
title: <The concept, in the reader's words>
description: <One plain sentence.>
---

<Plain-language explanation: what this is and why a reader would care,
before any Spor-specific vocabulary.>

## Small example

## How Spor represents this

## Commands/tools you might use

## What to read next
```

- Opening explanation: use plain language before canonical terms. Introduce a
  term such as `node` or `edge` only after the plain-language meaning it names.
- `Small example`: use a concrete fictional scenario. Draw from the tidefall
  billing-retry team, where `person-ines` and `person-marek` decide how many
  times to retry a failed card charge before asking the customer to update
  billing details.
- `How Spor represents this`: introduce the canonical vocabulary and the graph
  model here.
- `Commands/tools you might use`: point at the CLI verbs or MCP tools that touch
  the concept, linking their reference entries.
- `What to read next`: give two or three links, ordered by what the reader most
  likely needs next.

## What review checks

The PR template carries the checklist reviewers apply. It asks whether a new or
restructured page follows the matching template, and whether the page is written
for its section's reader: `start-here/` for someone deciding whether and how to
start, `use-spor/` for someone using Spor day to day, `hosted/` for members and
admins of a hosted organization, `reference/` for someone looking up exact
behavior, and `contributing/` for docs contributors.

Review also checks that setup and how-to pages include a working `Check it
worked` step. The voice must hold: no marketing intensifiers or persuasion
patterns. `scripts/check-style.sh` catches the known phrases in
`scripts/style-denylist.txt`; the [style guide's voice section](/contributing/style-guide/#voice)
is the full rule.

Examples must be fictional — invent a team and stay with it within a page, as
the [style guide's example data section](/contributing/style-guide/#example-data)
sets out — with no identifiers copied from a real graph. Nothing crosses the public-docs
boundary; `scripts/check-boundary.sh` is the backstop. If a page restates
mechanics owned by another page, such as a hosted page restating token or
attribution behavior, reviewers confirm the owning page was checked, and
updated where needed, in the same PR.
