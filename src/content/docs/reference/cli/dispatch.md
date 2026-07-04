---
title: Dispatch
description: Launch background agents against queue items, with agent identities, repo maps, and capability matching.
sidebar:
  order: 8
---

Dispatch turns a queue item into a running Claude Code background agent:
`dispatch` compiles a briefing and launches the session, `agent` manages the
identity it runs as, `repos` maps project slugs to directories on this
machine, and `capabilities` declares what this machine can run.

### agent

```
spor agent create <label> [--owner <id>] [--pubkey <fp>]
spor agent list
spor agent use <agent-id> [--clear]
spor agent token <agent-id> [--expires <Nd|date>] [--label <l>]
spor agent token <agent-id> list
spor agent token <agent-id> revoke <prefix>
```

**Mode:** dual (`token` is remote-only)

Create and manage agents — first-class `type: agent` nodes owned by a
person. A dispatched session runs as its agent, so its writes read "agent on
behalf of person" rather than person-direct. One durable agent per machine
or install, reused across dispatches.

| Subcommand | What it does |
| --- | --- |
| `agent create <label>` | create the agent and its `owned-by` edge. Without `--owner` the agent is owned by you (self-serve); `--owner <person-id>` creates it for another person (admin). In local mode the owner defaults to the sole person node. `--pubkey` records a public-key fingerprint (forward-compat, unenforced). |
| `agent list` | list agents and their owners |
| `agent use <agent-id>` | make it this machine's default dispatch identity — a local config write (`dispatch.agent`), not a graph write. `--clear` returns to person-scoped dispatch. |
| `agent token <agent-id>` | mint a long-lived standing PAT for the agent — the `SPOR_TOKEN` a headless agent runs under; shown once. `--expires` shortens the lifetime (default and max 1 year), `--label` tags it. `list` and `revoke <prefix>` manage them. Remote-only, owner-gated. |

```bash
spor agent create jo-laptop
spor agent use agent-jo-laptop
```

### dispatch

```
spor dispatch "<task>" | <node-id> [options]
```

**Mode:** dual · **Alias:** `bg`

Compile a briefing for a task and launch a Claude Code background agent in
the right repo. The target is free text, a node id, `--node <id>`,
`--from-queue` (the top-ranked item not already in flight on this machine),
or `--backfill` (the unattended init + enable + backfill primitive). The
target directory comes from the slug map ([`spor repos`](#repos)),
overridable with `--dir`.

In remote mode a node dispatch auto-claims the task, establishing the
heartbeat lease at dispatch time, so concurrent dispatch of the same node is
refused (the holder is named); `--no-claim` opts out. A node dispatch is
also refused when an agent for that node is already in flight on this
machine, or when the target is already resolved (a terminal status, or
retired by an inbound `resolves`/`answers` edge) — `--force` overrides both.

`--worktree` runs the agent in its own git worktree off the repo (branch
named for the node id or sanitized task), so parallel dispatches never race
the shared tree. Make it a repo default with the `dispatch.worktree` config
key, in the target repo's committable `.spor.json` or your machine-local
config; `dispatch.worktreeSetup` names a hook that preps each worktree,
running with the worktree as cwd and `SPOR_WORKTREE`, `SPOR_MAIN_CHECKOUT`,
and `SPOR_DISPATCH_SLUG`/`SPOR_DISPATCH_NODE` in the environment.
`--no-worktree` opts a single run out.

Two different agent axes — do not confuse them: `--as <agent-id>` picks the
Spor agent identity the dispatch runs as (attribution; remote-only; defaults
to `dispatch.agent`), while `--agent <A>` is the unrelated `claude --agent`
passthrough that picks the harness agent definition the session runs.

| Flag | Effect |
| --- | --- |
| `--dir <path>` | launch directory, overriding the slug map |
| `--node <id>`, `--slug <slug>` | dispatch a specific node; target a project slug |
| `--as <agent-id>` | Spor identity to run as (remote-only) |
| `--model <M>`, `--permission-mode <P>`, `--agent <A>`, `--name <N>` | passthroughs to `claude` |
| `--profile <profile-id>` | profile to run under, checked against this machine's capabilities |
| `--template <F>` | prompt template file with `{{brief}}`/`{{task}}`/`{{node}}`/`{{title}}`/`{{slug}}`/`{{dir}}`/`{{default}}` placeholders |
| `--full`, `--no-brief` | full briefing instead of the digest; raw prompt with no briefing block |
| `--no-claim`, `--force` | skip the auto-claim; dispatch despite an in-flight agent or resolved node |
| `--from-queue`, `--backfill` | top-ranked queue item; unattended repo backfill |
| `--worktree`, `--no-worktree` | per-run worktree isolation override |
| `--print` (alias `--dry-run`) | print the prompt, launch nothing |

```bash
spor dispatch task-api-rate-limits --worktree
spor dispatch --from-queue --print
```

### repos

```
spor repos [list | add <slug> <path> | rm <slug> | tags | tag <slug> [tag...] | untag <slug> [tag...]]
```

**Mode:** dual (the slug map is local; tags write the graph)

Two repo registers in one place.

The machine-local slug-to-directory map dispatch uses to find a repo. It
self-registers as you open sessions and lives in your user config:
`repos` lists it, `repos add <slug> <path>` maps a slug, `repos rm <slug>`
forgets one.

Repo-identity tags on the `repo-<slug>` graph node — the match key for a
norm's tag-scoped ride-along. An untagged repo excludes every tag-scoped
norm, so tagging is the deliberate opt-in that turns them on. `repos tags`
lists every repo node with its slugs and tags; `repos tag <slug> <tag...>`
sets (replaces) a repo's tags, and with no tags shows the current ones plus
auto-suggestions from disk; `repos untag <slug> [tag...]` removes tags (no
tags clears all).

```bash
spor repos add api ~/code/api
spor repos tag api python backend
```

### capabilities

```
spor capabilities [list [--json] | show <agent-id> | probe | publish | hosts <profile-id> | set <axis> <v...> | add|rm <axis> <v...> | allow-mcp <m...> | deny|undeny <profile-id...> | clear]
```

**Mode:** dual (`show`, `publish`, `hosts` are remote) · **Aliases:** `caps`, `profiles`

Show or edit the per-machine capability map dispatch matches against an
agent's profile. Harnesses, plugins, and skills self-probe each session;
declare what a probe cannot decide (reachable MCP servers, deny flags).
Declared augments probed; deny overrides both. Stored in the machine-local
config, never a committed `.spor.json`. The axes are `harnesses`,
`reachable_mcp`, `skills`, and `plugins`.

| Subcommand | What it does |
| --- | --- |
| `capabilities` | show this machine's effective capabilities |
| `probe` | re-probe harnesses, plugins, and skills now |
| `set <axis> <v...>` / `add` / `rm` | declare or adjust an axis |
| `allow-mcp <name...>` | declare a reachable MCP server |
| `deny <profile-id...>` / `undeny` | policy opt-out of a profile |
| `clear` | reset declarations and the probe cache |
| `publish` | push this machine's capabilities to the team fleet scheduler, keyed on `dispatch.agent` (run `spor agent use` once first). Session-start auto-publishes in remote mode; `SPOR_CAPABILITIES_PUBLISH=0` disables that. |
| `show <agent-id>` | read what a specific machine advertised (readable by the agent's owner, the agent itself, or an admin); pass `me` for this machine's own published record |
| `hosts <profile-id>` | which fleet machines satisfy a profile, and which cannot, with reasons. Scope with `--owner me\|person-x`; demote stale publishes with `--max-age 30m\|12h\|7d`. `spor dispatch` prints these automatically when this machine cannot satisfy a profile. |

```bash
spor capabilities allow-mcp spor
spor capabilities hosts profile-docs-writer
```
