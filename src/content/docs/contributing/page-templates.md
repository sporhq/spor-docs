---
title: Page templates
description: The three page shapes used across the docs — how-to, concept, and reference — and what review checks against them.
sidebar:
  order: 3
---

Most docs pages use one of three shapes: a **how-to page**, when the reader
wants to complete a task, a **concept page**, when the reader wants to
understand something, or a **reference page**, when the reader is looking up
exact behavior. Starting from the matching template keeps a new page
consistent with its neighbors, and the PR checklist asks which template a new
page follows.

## The orientation block

Every concept page and every reference landing page opens with the same
three-paragraph orientation block, immediately after the frontmatter.
Reference landing pages include section index pages and the standalone pages
directly under `reference/`.

```md
**Use this when** ...

**You do not need this if** ...

**After reading this, you should be able to** ...
```

- The `You do not need this if` line names where the reader should be instead,
  linked when a clear alternative page exists. When the honest answer is that
  the reader needs nothing else, saying so is enough. It is the line that gives
  permission to leave.
- The `After reading this` line names two or three checkable abilities.
- How-to pages keep their existing single `Use this when` sentence instead of
  the full block. That sentence is plain body prose, deliberately not bolded —
  the bolded **Use this when** lead-in belongs to the concept and reference
  block only.

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
- `Check it worked`: include this on every setup page, after the steps it
  verifies. The block has four parts: the command to run (for setup
  milestones, usually `spor status`); a fenced block of the output the reader
  should see; the most likely failure outputs — usually two or three — each
  paired with its exit (`If you see X, do Y`, `If this hangs, ...`, `If this says
  unauthorized, ...`); and a closing `Next step` line telling the reader where
  to go once the check passes. Expected output is real captured output with
  fictional identifiers, never an invented shape.
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

**Use this when** <the situation that calls for this concept page>.

**You do not need this if** <where the reader should go instead, with a link>.

**After reading this, you should be able to** <two or three checkable
abilities>.

<Plain-language explanation: what this is and why a reader would care,
before any Spor-specific vocabulary.>

## Small example

## How Spor represents this

## Commands/tools you might use

## What to read next
```

- Opening explanation: use plain language before canonical terms. Introduce a
  term such as `node` or `edge` only after the plain-language meaning it names.
- Orientation block: use the canonical block above, with the exit line pointing
  to the sibling page or task path the reader probably needs instead.
- `Small example`: use a concrete fictional scenario. Draw from
  [the tidefall scenario](/contributing/example-scenario/), where `person-ines`
  and `person-marek` decide how many times to retry a failed card charge
  before asking the customer to update billing details.
- `How Spor represents this`: introduce the canonical vocabulary and the graph
  model here.
- `Commands/tools you might use`: point at the CLI verbs or MCP tools that touch
  the concept, linking their reference entries.
- `What to read next`: give two or three links, ordered by what the reader most
  likely needs next.

## Reference pages

Use a reference page when the reader is looking up the exact behavior of a
surface: a command, endpoint, tool, schema type, or registry entry.

```md
---
title: <The surface, named plainly>
description: <One plain sentence.>
---

**Use this when** <the lookup situation this reference covers>.

**You do not need this if** <the sibling surface or task page the reader
should use instead>.

**After reading this, you should be able to** <two or three checkable
abilities>.

<Scope paragraph: what this reference covers and where the live contract is.>

## <One entry per verb, endpoint, or tool>
```

- Entries state exact, checkable behavior: what a command prints, what a
  response contains, or what happens on failure.
- The orientation block names the sibling surface a reader might want instead,
  such as CLI versus MCP versus REST.
- The full block opens reference landing pages: section index pages and the
  standalone pages directly under `reference/`. Deeper per-entry pages do not
  repeat it; their landing page carries the orientation.

## What review checks

The PR template carries the checklist reviewers apply. It asks whether a new or
restructured page follows the matching template, and whether the page is written
for its section's reader: `start-here/` for someone deciding whether and how to
start, `use-spor/` for someone using Spor day to day, `hosted/` for members and
admins of a hosted organization, `reference/` for someone looking up exact
behavior, and `contributing/` for docs contributors.

Review also checks that setup and how-to pages include a working `Check it
worked` step, that the step shows real expected output, and that likely
failure outputs are paired with their exits. It checks that concept pages and
reference landing pages open with the orientation block in its canonical form.
The voice must hold: no marketing intensifiers or persuasion patterns.
`scripts/check-style.sh` catches the known phrases in
`scripts/style-denylist.txt`; the
[style guide's voice section](/contributing/style-guide/#voice) is the full
rule.

Examples must be fictional and drawn from
[the tidefall scenario](/contributing/example-scenario/), as the
[style guide's example data section](/contributing/style-guide/#example-data)
sets out — with no identifiers copied from a real graph. Nothing crosses the public-docs
boundary; `scripts/check-boundary.sh` is the backstop. If a page restates
mechanics owned by another page, such as a hosted page restating token or
attribution behavior, reviewers confirm the owning page was checked, and
updated where needed, in the same PR.
