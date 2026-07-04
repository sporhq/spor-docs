---
title: Contributing to the docs
description: Prepare a docs pull request with the right page structure, local checks, and public-boundary rules.
sidebar:
  order: 1
---

The `github.com/sporhq/spor-docs` repository is the source for
`docs.sporhq.io`. It is an Astro Starlight site, and its pages are Markdown or
MDX files under `src/content/docs/`. A typo fix and a new reference page use
the same pull request flow: edit the page, preview it locally, run the checks,
and open the PR with the behavior you verified.

## Local setup

Use Node 24, which is the version CI builds with. Then:

```sh
npm install
npm run dev      # live preview at localhost:4321
npm run build    # static build into dist/
```

Run the build before opening a PR — it produces the static site and catches
broken frontmatter and other errors that the dev server tolerates.

## Where pages live

Each sidebar section has one directory under `src/content/docs/`:

- `start-here/` — installation, the quickstarts, connecting an AI assistant,
  and core ideas.
- `use-spor/` — the everyday working loop: capture, the queue, briefings,
  identity, and dispatch.
- `hosted/` — the hosted product: organizations, sign-in, tokens, and your
  data.
- `reference/` — the CLI in `reference/cli/`, MCP in `reference/mcp/`, REST API
  in `reference/api/`, the schema and graph model in
  `reference/graph-model/`, plus configuration, costs, and diagnostics pages.
- `contributing/` — this guide, the style guide, the page templates, and
  the canonical example scenario.

Filenames are kebab-case and become the URL slug. Most sidebars are generated
from their directory, so a new page appears once its frontmatter is in place.
The Reference section's group structure is assembled in `astro.config.mjs`; a
new top-level reference page needs an entry there too. Moving or renaming a
page changes its URL — add a redirect from the old path in `astro.config.mjs`
when you do.

Every page starts with Starlight frontmatter. `title` and `description` are
required. The description is one plain sentence shown in search results and
link previews. `sidebar.order` sets the page's position within its section.

New pages start from one of the three [page templates](/contributing/page-templates/):
how-to for task-shaped pages, concept for understanding-shaped pages,
reference for exact-behavior lookups.

Reference entries describe shipped behavior. Verify the client surface and
the graph model against the public client package
[`@sporhq/spor`](https://github.com/sporhq/spor) — its README and API docs.
Verify CLI entries against the CLI's own help output, such as `spor help` or
`spor <verb> --help`; when the docs and help output disagree, the help output
wins. Verify API and MCP entries against the observed behavior of a server
you can access. If a page contradicts shipped behavior, fix it — citing what
the tool actually prints or returns in the PR description — or file a
[documentation error issue](https://github.com/sporhq/spor-docs/issues/new?template=docs-error.md).

## The quality bar

Every docs PR is reviewed against four reader tests in addition to the local
checks:

- A new reader should know what Spor is before learning its data model.
- A setup page should produce a visible result in under five minutes.
- A reference page should start with when to use it.
- Public docs should describe user-facing behavior, not private infrastructure.

The [page templates](/contributing/page-templates/) build these tests into new
pages: how-to pages state "Use this when" up front and include a "Check it
worked" step, and reference pages use the same opening move when they explain
when to use the entry. `scripts/check-boundary.sh` is the mechanical backstop for the fourth
test, but the review is broader than the denylist. Reviewers apply the bar to
the pages a PR touches; a page that fails one test is revised before it ships.

## How pages are produced

Reference entries for CLI commands, API routes, MCP tools, and the graph model
may be generated or heavily derived from their source of truth: `spor help`,
`spor <verb> --help`, the public client package `@sporhq/spor`, or observed
server behavior. Their shape is uniform and their claims are checkable. A
generated entry is still verified against its source before it ships.

Learning pages, including quickstarts, tutorials, how-tos, and concept pages,
require human editorial review. A person reads and edits every one; a generated
draft never ships unedited as a learning page.

Landing pages and section index pages are written fresh from the reader's
situation, rather than assembled from passages of existing pages. Inherited
phrasing should not anchor them.

No tutorial or quickstart ships until someone who did not build the feature
follows it successfully. This is the strongest check a learning page gets, and
no lint substitutes for it.

## Checks before a PR

Three repo-specific checks run on every PR and also run locally.
`scripts/check-boundary.sh` keeps the public docs abstract: private repository
paths, server deployment internals, and real identifiers from any team's graph
are banned. The machine-readable list is `scripts/boundary-denylist.txt`. When
this check fails, rewrite the passage abstractly or replace the identifier
with a fictional one. Do not edit the denylist or the script in a docs PR.

`scripts/check-style.sh` scans pages under `src/content/docs/`, except the
style guide, for the phrases in `scripts/style-denylist.txt`. When this check
fails, rewrite the passage as a plain, checkable claim. Do not edit the
denylist or the script in a docs PR.

`scripts/check-token-parity.sh` verifies that `src/styles/tokens.css` remains
a byte-identical vendored copy of the canonical Spor design tokens. Do not edit
that file in a docs PR; site-specific styling belongs in
`src/styles/theme.css`.

For prose, follow the [style guide](/contributing/style-guide/). It covers the
voice, canonical casing, example-data rules, and formatting conventions used
across the docs.
