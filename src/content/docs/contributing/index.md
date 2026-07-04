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
- `contributing/` — this guide and the style guide.

Filenames are kebab-case and become the URL slug. Most sidebars are generated
from their directory, so a new page appears once its frontmatter is in place.
The Reference section's group structure is assembled in `astro.config.mjs`; a
new top-level reference page needs an entry there too. Moving or renaming a
page changes its URL — add a redirect from the old path in `astro.config.mjs`
when you do.

Every page starts with Starlight frontmatter. `title` and `description` are
required. The description is one plain sentence shown in search results and
link previews. `sidebar.order` sets the page's position within its section.

Reference entries describe shipped behavior. Verify the client surface and
the graph model against the public client package
[`@sporhq/spor`](https://github.com/sporhq/spor) — its README and API docs.
Verify CLI entries against the CLI's own help output, such as `spor help` or
`spor <verb> --help`; when the docs and help output disagree, the help output
wins. Verify API and MCP entries against the observed behavior of a server
you can access. If a page contradicts shipped behavior, fix it — citing what
the tool actually prints or returns in the PR description — or file a
[documentation error issue](https://github.com/sporhq/spor-docs/issues/new?template=docs-error.md).

## Checks before a PR

Two repo-specific checks run on every PR and also run locally.
`scripts/check-boundary.sh` keeps the public docs abstract: private repository
paths, server deployment internals, and real identifiers from any team's graph
are banned. The machine-readable list is `scripts/boundary-denylist.txt`. When
this check fails, rewrite the passage abstractly or replace the identifier
with a fictional one. Do not edit the denylist or the script in a docs PR.

`scripts/check-token-parity.sh` verifies that `src/styles/tokens.css` remains
a byte-identical vendored copy of the canonical Spor design tokens. Do not edit
that file in a docs PR; site-specific styling belongs in
`src/styles/theme.css`.

For prose, follow the [style guide](/contributing/style-guide/). It covers the
voice, canonical casing, example-data rules, and formatting conventions used
across the docs.
