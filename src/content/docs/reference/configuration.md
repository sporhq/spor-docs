---
title: Configuration
description: The config cascade, the repo markers, environment variables, and the credential store.
---

Every verb resolves its settings the same way: through one cascade of
sources, a per-repo marker pair, and a machine-local credential store. This
page is the reference for all three.

## The cascade

Spor reads configuration from several places; more specific sources win over
broader ones.

1. CLI flags
2. environment variables (`SPOR_SERVER`, `SPOR_TOKEN`, …)
3. repo config: `.spor.json`
4. user config: `$SPOR_HOME/config.json`
5. global config: `~/.config/spor/config.json`
6. built-in defaults

One exception sits above the environment: a `graph: <path>` binding in a
repo's `.spor` marker overrides `SPOR_HOME` (so a contributor with a
personal global `SPOR_HOME` still inherits a shared graph inside a
shared-graph repo), while an explicit CLI `--home` still beats it.

Never commit a team token into `.spor.json`. Use the environment, user
config, or global config for secrets.

## Mode resolution

Setting `SPOR_SERVER` switches the client into remote mode; unset means
local mode, reading the graph at `$SPOR_HOME` (default `~/.spor/`) directly.
`spor status` reports what resolved. Mode and activation are separate: a
globally configured `SPOR_SERVER` resolves the mode to remote but does not
by itself enable an unrelated repo.

## The repo markers

Two committable files at a repo root scope Spor to that repo.

**`.spor`** is a flat `key: value` identity marker:

```
repo: billing
graph: ../team-graph    # local mode: bind this repo to a shared graph home
org: acme               # remote mode: select a stored tenant
```

`repo:` fixes the project slug ([`spor link`](/reference/cli/repo-scoping/#link)
writes it). `graph:` binds the repo to a graph home, resolved relative to
the marker itself; nearest-ancestor marker wins, and it applies in local
mode only. `org:` is the remote-mode sibling: it selects which stored
credential the repo uses.

**`.spor.json`** is JSON configuration:

```json
{
  "enabled": true,
  "queue": { "project": "billing" },
  "dispatch": { "worktree": true }
}
```

Spor is opt-in per repo. A repo is active when an `enabled` flag is set
anywhere in the cascade (`enabled: true`/`false` in a config layer,
`SPOR_ENABLED=1`/`0`, or a CLI flag) or a `.spor`/`.spor.json` marker is
present in the cwd ancestry; an explicit flag wins over marker presence, so
`enabled: false` forces a no-op even where a marker exists. The default —
no flag, no marker — is off, including in remote mode, so side projects
never leak into a team graph by accident.

## Environment variables

| Variable | Effect |
| --- | --- |
| `SPOR_SERVER` | team-server base URL; setting it resolves the mode to remote |
| `SPOR_TOKEN` | auth token — the non-interactive/CI path, bypassing the credential store |
| `SPOR_ORG` | select a stored tenant by org slug |
| `SPOR_HOME` | the local graph home (default `~/.spor/`) |
| `SPOR_QUEUE_PROJECT` | default scope for [`spor next`](/reference/cli/reading-the-graph/#next) (the `queue.project` config key) |
| `SPOR_ENABLED` | `1`/`0` — force repo activation on or off, above marker presence |
| `SPOR_CAPABILITIES_PUBLISH` | `0` disables the session-start capability auto-publish |

Legacy `SUBSTRATE_*`-prefixed spellings of these variables are still read as
a back-compat window, and older `sub_pat_` tokens stay valid — no re-mint
required.

## The credential store

Server tokens are org-scoped, so a person in N orgs holds N credentials.
They live in a store keyed by `(server, org)` at
`$SPOR_HOME/auth/credentials.json` — mode `0600`, machine-local, never
committed.

[`spor auth login`](/reference/cli/getting-started/#auth) (device grant) and
[`spor join`](/reference/cli/getting-started/#join) (paste) both add a tenant and
never overwrite a sibling; the first tenant becomes the active default.
`spor auth list`, `switch`, `whoami`, and `logout` manage the store. A
401/403 on a tenant carrying a refresh token transparently refreshes against
its issuer and retries once.

Which credential is active — the tenant selector, highest wins:

1. `--org`/`--server` flag
2. `SPOR_SERVER` (with `SPOR_TOKEN`) or `SPOR_ORG` environment
3. the repo `.spor` marker's `org:` key (committable, nearest ancestor)
4. the store's `default`
5. legacy flat `config.json` `server`+`token` (migrated on read)
6. local mode
