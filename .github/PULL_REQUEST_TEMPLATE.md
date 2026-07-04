## Summary

<!-- One or two sentences: what changed and why. If this fixes a docs error,
     cite the shipped behavior (command output, response body) that the old
     text contradicted. -->

## Checklist

- [ ] `npm run build` passes locally
- [ ] `scripts/check-boundary.sh` and `scripts/check-style.sh` pass
- [ ] A new or restructured page follows the matching [page template](https://docs.sporhq.io/contributing/page-templates/) (how-to or concept)
- [ ] The page is written for its section's reader
- [ ] Setup and how-to pages include a "Check it worked" step the reader can run
- [ ] Voice and terminology match the [style guide](https://docs.sporhq.io/contributing/style-guide/) — no persuasion patterns or marketing phrasing (the style lint catches only the known phrases)
- [ ] Examples are fictional and drawn from the canonical tidefall walkthrough — no identifiers copied from a real graph
- [ ] No private internals — the server is described abstractly (see [CONTRIBUTING.md](https://github.com/sporhq/spor-docs/blob/main/CONTRIBUTING.md))
- [ ] If the change touches a page that restates mechanics owned by another page, the owning page was checked and updated in the same PR
