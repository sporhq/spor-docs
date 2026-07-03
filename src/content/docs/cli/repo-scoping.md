---
title: Repo scoping
description: Opt repos in or out, fix their project identity, and compile briefings.
sidebar:
  order: 6
---

Spor is opt-in per repository: a repo with no `.spor` or `.spor.json` marker
is a no-op. These verbs manage that marker, plus the compile surface that
turns the graph into briefings.

### enable

```
spor enable
```

**Mode:** local

Set `{ "enabled": true }` in this repo's committable `.spor.json` — how you
turn Spor on for a repo, and how you undo a prior `spor disable`. Commit the
file to share the setting.

```bash
spor enable
```

### disable

```
spor disable
```

**Mode:** local

Set `{ "enabled": false }` in this repo's committable `.spor.json`. The
hooks then no-op here until re-enabled.

```bash
spor disable
```

### link

```
spor link <slug>
```

**Mode:** local

Write a `.spor` identity marker (`repo: <slug>`) at the repo root, fixing a
wrong inferred slug deterministically. The slug must be canonical
(`^[a-z0-9][a-z0-9-]*$`); with no slug it uses the inferred one. Commit the
marker to share the identity.

```bash
spor link billing
```

### compile

```
spor compile [--root <id>] [--query <text>] [--project <slug>] [--nodes <dir>] [--digest] [--skeleton] [--min-sim <n>] [--out <file>] [--quiet]
```

**Mode:** dual

Compile a node neighborhood or a prompt-time digest — the machinery behind
briefings. `--root <id>` compiles a node's neighborhood; `--query <text>`
compiles from free text (semantic search); `--digest` emits a compact
prompt-time digest. In remote mode the server compiles; `--skeleton`
(a versioned briefing-node skeleton, root mode) is local-only, and an
explicit `--nodes` always names a local checkout, even under a server.
`--min-sim` gates query-mode relevance (default 0.08), `--project` scopes
project-level corrections, `--out` writes to a file, `--quiet` suppresses
the stderr stats.

```bash
spor compile --query "auth token rotation" --digest
```

### brief

```
spor brief <id>
```

**Mode:** dual

Compile a briefing for one node — sugar for `compile --root <id>`.

```bash
spor brief dec-payments-stripe
```

### validate

```
spor validate [--nodes <dir>]
```

**Mode:** local

Lint the local graph and exit 1 on errors. In remote mode the server
validates every write, so this fails fast unless `--nodes` points at a local
checkout.

```bash
spor validate
```
