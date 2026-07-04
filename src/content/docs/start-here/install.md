---
title: Install
description: Install the Spor CLI with npm, wire it into your coding agent, and opt a repository in.
sidebar:
  order: 3
---

## Requirements

- Node.js 20 or newer.

Local mode needs nothing else — no database, no server.

## Install the package

```bash
npm install -g @sporhq/spor
```

This installs two commands:

- `spor` — the CLI you use directly
- `spor-hook` — the hook dispatcher that agent hosts call; you rarely run it
  yourself except for [`spor-hook doctor`](/reference/diagnostics/)

Check the install:

```bash
spor --help
```

## Wire your coding agent

`spor install` connects Spor to an agent host so sessions get briefed
automatically. Supported hosts: `claude`, `codex`, `gemini`, `cursor`,
`copilot`, `opencode`.

```bash
spor install claude
```

With no host named, it lists what it detects on your machine and changes
nothing:

```bash
spor install            # detect only
spor install --all      # install into every detected host
spor install --print    # dry run: show what would change
```

Claude Code is wired through its plugin CLI; the other hosts receive a merged
hooks manifest. Re-running `spor install` is safe — it refreshes paths and
does not duplicate hooks.

The default scope is `--scope user`, which installs Spor for you across
repositories. `--scope repo` writes configuration into the current checkout
so it can be committed and shared.

## Upgrading

A new npm release does not change what an agent has already loaded — some
hosts cache the plugin or hook definitions. Upgrade in two steps:

```bash
npm install -g @sporhq/spor   # update the package
spor upgrade                  # refresh every wired host to the new version
```

`spor upgrade claude` targets one host, and `--print` previews the changes
without writing. `spor status` warns when a loaded plugin is older than the
installed package.

## Per-repo opt-in

Installing Spor does not activate it in every repository you open. A repo is
inactive until it carries a `.spor` or `.spor.json` marker, which keeps
side-project context out of a team graph by accident.

```bash
spor enable        # write {"enabled": true} to this repo's .spor.json
spor disable       # write {"enabled": false}; hooks no-op here until re-enabled
spor link harbor   # write a .spor marker fixing this repo's project slug
```

All three write committable files, so the setting travels with the
repository. `spor link` matters when the slug Spor infers from the directory
name is wrong — the slug is how nodes, queues, and briefings are scoped to a
project.

:::note
Never commit a team token into `.spor.json`. Tokens belong in the
environment (`SPOR_TOKEN`) or in your user config, which `spor join` and
`spor auth login` manage for you.
:::

Next: the [local quickstart](/start-here/local-quickstart/) or the
[hosted quickstart](/start-here/hosted-quickstart/).
