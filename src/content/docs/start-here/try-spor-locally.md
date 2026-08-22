---
title: Try Spor locally
description: Install the CLI, create a local graph, record one issue, and read it back.
sidebar:
  order: 3
---

Use this path when you want to see Spor work on your own machine before a
team or server is involved. It takes about five minutes end to end, including
installation.

## 1. Install the CLI

You need Node.js 20 or newer. Local mode needs nothing else: no database and
no server.

```sh
npm install -g @sporhq/spor
```

This installs two commands:

- `spor`, the CLI you use directly
- `spor-hook`, the hook dispatcher that agent hosts call; you rarely run it
  yourself

Check the install:

```sh
spor --help
```

You should see a usage listing that begins:

```text
spor — Spor client CLI
```

If the shell says `spor: command not found`, open a new terminal first. If it
is still missing, npm's global bin directory is not on your PATH.

## 2. Create the graph home

```sh
spor init
```

This creates the graph home: a `nodes/` directory, a git repository to
version it, and a `.gitignore` for machine-local state. The default location
is `~/.spor`; set `SPOR_HOME` to put it somewhere else.

`spor init` is idempotent. Re-running it reports an existing graph and never
clobbers one.

## 3. Create your person node

```sh
spor person create
```

This writes an entry for you in the record. The docs call these entries
nodes; this one has `type: person` and is seeded from your git identity
(`git config user.name` / `user.email`). It is how the queue and briefings
know which items are yours.

Override the seeded values if they are wrong:

```sh
spor person create 'Ines Duarte' --email ines@tidefall.example.com
```

This command is idempotent too.

You should see a confirmation like:

```text
created person Ines Duarte (person-9c2f51ab84d03e77) <ines@tidefall.example.com>
```

The id is derived automatically; `--id` picks your own.

## Check it worked

Run:

```sh
spor status
```

A healthy local graph looks like:

```text
mode:     local  (not enabled here — run /spor:onboard to set up, or 'spor enable' to opt in; hooks are a no-op)
repo:     billing
graph:    /home/ines/.spor/nodes (1 nodes)
node:     20.11.0 (>= 20 required, OK)
```

The `graph:` line with a node count is the success signal. The one node is
your person node. The `(not enabled here …)` note on the `mode:` line is
expected at this point; it is about per-repository hooks, which
[What happens automatically](/use-spor/what-happens-automatically/) covers,
and it does not affect anything on this page.

- If the `graph:` line says `not created — run 'spor init'`, step 2 has not
  run in this shell; check that `SPOR_HOME` points where you meant.
- If the `node:` line reports a version below 20, upgrade Node.js and
  reinstall.

Next step: record your first node below.

## 4. Record your first node

```sh
spor add "A retry that succeeds while the payment provider's webhook is delayed can charge the card twice. Fix before the rollout." --type issue
```

You should see:

```text
added issue-a-retry-that-succeeds-while-the-payment-provider (issue) to /home/ines/.spor/nodes
  edit it to add edges/detail; 'spor next' will surface it.
```

In local mode this writes a well-formed, validated node file. You never
hand-author frontmatter. The default type is `task`; `--type`, `--title`,
and `--id` override the defaults. Spor infers the repo slug from the
current directory, or you can set it with `--project`.

## 5. Read the queue

```sh
spor next
```

You should see:

```text
1. [0] issue-a-retry-that-succeeds-while-the-payment-provider — A retry that succeeds while the payment provider's webhook is (issue)
   queueable and live
```

`spor next` shows the ranked list of open work, ordered by graph signals such
as what each item blocks. Your new issue appears here.

## 6. Compile a briefing

```sh
spor compile --query "billing retry flow"
```

This compiles the neighborhood of entries relevant to a free-text query. It
is the same operation that produces the automatic session-start briefing.

## Where the graph lives

Everything is under `$SPOR_HOME`, which defaults to `~/.spor`: one markdown
file per node, versioned by git. `git -C ~/.spor log` shows the history.

Because the graph lives outside your code repositories, context recorded on a
branch survives even if the branch never merges.

## What you now know

- Local mode is a plain git repository of markdown files on your machine.
- `spor init` creates the graph home, and `SPOR_HOME` moves it.
- `spor person create` records who you are for queues and briefings.
- `spor add`, `spor next`, and `spor compile` are the basic local loop.

## Where to go next

- [What happens automatically](/use-spor/what-happens-automatically/) to wire
  Spor into your coding agent so sessions get briefed automatically.
- [Core ideas](/start-here/core-ideas/) for the graph model behind what you
  just did.
- [Use Spor](/use-spor/) for the day-to-day loop.
- [I was invited to hosted Spor](/start-here/invited-to-hosted-spor/) when a
  team wants to share one live graph.
