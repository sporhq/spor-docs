# Spor documentation

The source for [docs.sporhq.io](https://docs.sporhq.io) — documentation for
[Spor](https://github.com/sporhq/spor), a typed, versioned knowledge graph of
the durable outcomes of work.

Built with [Astro Starlight](https://starlight.astro.build). Pages are
Markdown/MDX under `src/content/docs/`.

## Developing

```sh
npm install
npm run dev        # local preview at localhost:4321
npm run build      # static build into dist/
```

## Checks

CI runs six repo-specific checks besides the build; all run locally too:

```sh
scripts/check-boundary.sh             # no private internals or real graph data
scripts/check-style.sh                # no banned phrases, exclamation marks, or emoji in docs prose
scripts/check-token-parity.sh         # vendored design tokens match canonical
scripts/check-view-tools-parity.sh    # widget.md's view-carrying tools match tools.md
scripts/check-llms-txt-parity.sh      # llms.txt lists every page, with no orphaned URLs
scripts/check-redirects.sh            # redirect table has no stale sources, duplicates, broken targets, or chains
```

`src/styles/tokens.css` is a verbatim vendored copy of the canonical Spor
design tokens and is never edited here — site styling belongs in
`src/styles/theme.css`, which maps the tokens onto Starlight's variables.
Maintainers re-sync tokens with `scripts/sync-tokens.sh`.

## Contributing

Contributions are welcome. [CONTRIBUTING.md](CONTRIBUTING.md) covers local
setup, page conventions, and what to do when a CI check fails; prose
follows the [style guide](https://docs.sporhq.io/contributing/style-guide/).

## License

[Apache-2.0](LICENSE).
