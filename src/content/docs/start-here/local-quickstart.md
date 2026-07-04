---
title: Local quickstart
description: Create a graph on your machine, record your first node, and read the queue — no server required.
sidebar:
  order: 4
---

In local mode the graph lives entirely on your machine, as a plain git
repository of markdown files. This quickstart takes about two minutes and
assumes you have [installed the CLI](/start-here/install/).

## 1. Create the graph home

```bash
spor init
```

This creates the graph home — a `nodes/` directory, a git repository to
version it, and a `.gitignore` for machine-local state. The default location
is `~/.spor`; set `SPOR_HOME` to put it somewhere else. `spor init` is
idempotent: re-running it reports an existing graph and never clobbers one.

## 2. Create your person node

```bash
spor person create
```

This writes a `type: person` node seeded from your git identity
(`git config user.name` / `user.email`). It is how the queue and briefings
know which items are yours. Override the seeded values if they are wrong:

```bash
spor person create 'Priya Nair' --email priya@example.com
```

Like `init`, it is idempotent — a re-run that finds a node already bound to
your git identity reports it and exits 0.

## 3. Record your first node

`spor add` captures a node from a couple of sentences of prose. In local mode
it writes a well-formed, validated node file, so you never hand-author
frontmatter:

```bash
spor add "The export API returns 429 without a Retry-After header, so \
clients cannot back off correctly. Fix before the beta." --type issue
```

The default type is `task`; `--type`, `--title`, and `--id` override the
defaults. The project slug is inferred from the current directory, or set it
with `--project`.

## 4. Read the queue

```bash
spor next
```

`spor next` shows the ranked decision queue — open work ordered by graph
signals such as what each item blocks and how its neighborhood has been
moving. Your new issue appears here. `--limit N` changes the page size and
`--type task,issue` filters by node type.

## 5. Compile a briefing

```bash
spor compile --query "export api rate limiting"
```

This compiles the neighborhood of nodes relevant to a free-text query — the
same operation that produces the automatic session-start briefing. Add
`--digest` for a compact, prompt-sized form, or use `--root <id>` to compile
around one specific node.

## Where the graph lives

Everything is under `$SPOR_HOME` (default `~/.spor`): one markdown file per
node in `nodes/`, versioned by git. `git -C ~/.spor log` shows the history of
your project memory, and diffs, branches, and backups work the way they do in
any git repository. Because the graph lives outside your code repositories,
context recorded on a branch survives even if the branch never merges.

## Next

Run `spor enable` in a repository you work in, so the
[session hooks](/start-here/what-happens-automatically/) brief your
coding agent from this graph automatically. When a team wants to share one
live graph, move to the
[hosted quickstart](/start-here/hosted-quickstart/).
