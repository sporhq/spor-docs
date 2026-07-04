---
title: Repo scoping
description: Opt repos in or out, fix their project identity, and compile briefings.
sidebar:
  order: 7
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

```sh
spor enable
```

### disable

```
spor disable
```

**Mode:** local

Set `{ "enabled": false }` in this repo's committable `.spor.json`. The
hooks then no-op here until re-enabled.

```sh
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

```sh
spor link billing
```

### agents-md

```
spor agents-md [--briefing] [--no-claude-md]
```

**Mode:** local · alias `agents`

Write or idempotently refresh the managed Spor block in `AGENTS.md` at the
repo root — standing, user-voice instructions that keep the graph current
(capture discovered work as it appears, file issues before fixing, prefer the
graph over private notes for durable facts, resolve with artifacts, add
`Spor:` commit trailers). Committed, it reaches every contributor and
dispatched agent. `spor enable` runs this for you, and `spor upgrade`
refreshes the wording. If a `CLAUDE.md` exists that never mentions
`AGENTS.md`, an `@AGENTS.md` import is appended so those sessions inherit the
directive too (suppress with `--no-claude-md`). By default the block carries
the directive only — hooked hosts get their briefing at session start;
`--briefing` also embeds the standing project briefing, the floor for hosts
without hooks.

```sh
spor agents-md --briefing
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

```sh
spor compile --query "billing retry flow" --digest
```

### brief

```
spor brief <id>
```

**Mode:** dual

Compile a briefing for one node — sugar for `compile --root <id>`.

```sh
spor brief task-tidefall-retry-emails
```

### validate

```
spor validate [--nodes <dir>]
```

**Mode:** local

Lint the local graph and exit 1 on errors. In remote mode the server
validates every write, so this fails fast unless `--nodes` points at a local
checkout.

```sh
spor validate
```
