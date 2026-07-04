---
title: Style guide
description: Voice, terminology, example data, and formatting conventions for contributors to the Spor docs.
sidebar:
  order: 2
---

This page is for contributors.
[Contributing to the docs](/contributing/) covers the mechanics of a docs PR;
this page holds the voice, terminology, and formatting rules.

## Voice

The Spor voice is evidentiary, calm, and precise. State what is; cite the
behavior. A reference entry earns trust by matching what the tool actually
does, so the strongest sentence in a docs page is usually a checkable one:
what a command prints, what a response contains, what happens on failure.

In practice:

- Write in the present tense about shipped behavior. If something is planned
  rather than shipped, say so plainly and once — the under-construction asides
  on the section index pages are the model.
- No hype. Spor is not "powerful", "seamless", or "blazingly fast"; it ranks a
  queue, compiles a briefing, records a node. Say the second kind of thing.
- No exclamation marks, no emoji, no rhetorical questions as headings.
- Prefer the concrete claim to the general one. "`spor next` ranks open items
  by what they block, neighborhood activity, and age" tells the reader
  something; "surfaces the most relevant work" does not.
- When behavior differs between local and remote mode, say which mode a
  statement applies to rather than hedging with "may" or "typically".

## Terminology

Use these terms with this casing, and use the same term every time — a
reference that alternates between two names for one thing reads as two things.

| Term                    | Casing and usage                                                                        |
| ----------------------- | --------------------------------------------------------------------------------------- |
| Spor                    | Capitalized as the product name. The binary and package are lowercase in code: `spor`, `@sporhq/spor`. |
| node                    | Lowercase. One markdown file recording one fact — a decision, task, issue, norm, or question. |
| edge                    | Lowercase. A typed, directional link between two nodes.                                 |
| summary                 | Lowercase. The one-line statement of a node, distinct from its body.                    |
| briefing                | Lowercase. The compiled context Spor assembles for a task before work starts.           |
| digest                  | Lowercase. The periodic roll-up of recent graph activity.                               |
| queue                   | Lowercase. The ranked list of open work; "decision queue" on first use in a page is fine. |
| lens                    | Lowercase. A saved view over the graph — board, table, or lineage tree.                 |
| claim                   | Lowercase. A time-bounded hold on a queue item, taken so two sessions do not work it at once. |
| capture                 | Lowercase, verb and noun. Recording a finding or deferral as prose for the server to type and link. |
| distill                 | Lowercase, verb. Reducing working context to the short prose a capture sends.           |
| steward                 | Lowercase. The person answerable for a node or an area of the graph.                    |
| the gardener            | Lowercase, with the article. The background process that tends the graph — sweeps, consolidation, staleness. |
| local mode              | Lowercase. The graph is a plain git repository on your machine.                         |
| remote mode             | Lowercase. The graph lives on a shared server the CLI talks to.                         |
| personal access token   | Lowercase, spelled out on first use in a page; "PAT" is fine after that.                |

## Example data

Every identifier in an example is invented. Never copy from a real graph —
not a node id, not a person handle, not an organization name, not a token.
The boundary lint catches known real identifiers, but it can only list what
it knows about; the rule is the contract, the lint is a backstop.

The docs share one canonical fictional scenario: the tidefall billing-retry
story documented on [The tidefall scenario](/contributing/example-scenario/).
Pages draw scenes from it rather than inventing a new team per page.

- Stay inside the canonical scenario so examples read as one coherent story
  across pages. The organization is `tidefall`, with people `person-ines` and
  `person-marek`; extend the scenario page when you need an object it lacks.
- Give fictional node ids the real shape: a type prefix and a kebab-case
  slug, like `dec-tidefall-billing-retries` or
  `task-tidefall-retry-emails`.
- Secrets and tokens are placeholders that cannot be mistaken for live
  values: `<your-token>`, or an obviously truncated form. Never paste a real
  token, even a revoked one.
- Example hostnames use your fictional org (`tidefall.example.com`) or the
  reserved `example.com` family — not a real team's domain.

## Formatting

- Headings are sentence case: "Adding a reference entry", not "Adding a
  Reference Entry".
- Commands go in fenced code blocks with a language tag (`sh` for shell) and
  no prompt characters — no leading `$` or `>` — so the block is paste-ready.
  Put expected output in its own block or mark it with a comment, not on the
  line after the command in the same block.
- Filenames are kebab-case and become the URL slug; pick the name you want in
  the URL.
- Use Starlight asides (`:::note`, `:::caution`) sparingly — for a genuine
  caveat the reader would otherwise miss, not for emphasis. A page with an
  aside per section has none.
- Link text describes the destination ("the CLI reference"), never "click
  here" or a bare URL in prose.
- Bold is for UI labels, first-use definitions, and the orientation block
  lead-ins (**Use this when** / **You do not need this if** / **After reading
  this, you should be able to**), backticks for anything the reader would type
  or read verbatim: commands, flags, filenames, node ids, environment
  variables.
