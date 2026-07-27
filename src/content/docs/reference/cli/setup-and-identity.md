---
title: Setup and identity
description: Install the CLI into your agent, create or join a graph, and establish who you are.
sidebar:
  order: 3
---

The verbs that take you from a fresh install to a working graph: create a
local one, wire Spor into a coding agent, sign in to a team server, and
establish the identity your writes are attributed to.

For what each mode badge means, see the [overview](/reference/cli/). For where these
verbs read their settings, see [Configuration](/reference/configuration/).

### init

```
spor init
```

**Mode:** local

Create the local graph home: a `nodes/` directory, a git repository to
version it, and a `.gitignore` for machine-local state. Idempotent — an
existing graph is reported, never clobbered.

```sh
spor init
```

### install

```
spor install [host...] [--scope <user|repo>] [--all] [--print] [--server <url>] [--token <tok>]
```

**Mode:** local · **Alias:** `setup`

Wire the Spor hooks or plugin into one or more host agents (`claude`,
`codex`, `gemini`, `opencode`, `copilot`, `cursor`). With no host it lists
the hosts detected on the machine and touches nothing. `--server`/`--token`
also persist team-graph credentials to your user config.

| Flag | Effect |
| --- | --- |
| `--scope <user\|repo>` | where to write: `user` (default) or `repo` (this checkout) |
| `--all` | install into every detected host |
| `--print` (alias `--dry-run`) | show what would change, write nothing |
| `--server <url>`, `--token <tok>` | persist remote-graph credentials to user config |

```sh
spor install claude
```

### upgrade

```
spor upgrade [host...] [--scope <user|repo>] [--print] [--no-net]
```

**Mode:** local · **Alias:** `update`

Refresh wired hosts to the package version on disk after an npm bump — a
bumped package does not change what an agent already loaded. With no host it
refreshes every detected host that has Spor wired, and flags a newer release
published to npm (`--no-net` skips that check).

```sh
spor upgrade claude --print
```

### status

```
spor status
```

**Mode:** dual

Print the resolved mode (local or remote), graph home, repo slug,
identity, and a health probe. The first thing to run when Spor is not doing
what you expect.

```sh
spor status
```

### join

```
spor join [url] <token> [--server <url>] [--token <tok>]
```

**Mode:** remote

Add a team-graph credential to the multi-tenant store, keyed by
`(server, org)`, and confirm it against the server. A person in N orgs holds
N credentials; `join` never overwrites a sibling tenant. Omit the URL to
join the hosted Spor service — a token-shaped first positional is read as
the token. For interactive sign-in without a pasted token, use
[`auth login`](#auth).

```sh
spor join spor_pat_abc123
spor join https://graph.example.com spor_pat_abc123 --org tidefall
```

### auth

```
spor auth <login|list|switch|whoami|logout>
```

**Mode:** remote

Acquire and manage org-scoped credentials. Server tokens are org-scoped, so
these verbs populate and select within the credential store (see
[Configuration](/reference/configuration/#the-credential-store)) and never clobber
a sibling tenant.

| Subcommand | What it does |
| --- | --- |
| `auth login` | interactive sign-in; the default is the device authorization grant (RFC 8628), which works headless over SSH — it prints a code and URL you approve in any browser. Flags: `--server <url>`, `--org <slug>`, `--web` (localhost-loopback auth-code + PKCE, falling back to device-code), `--all` (one token per org membership), `--no-open`. `auth login <url> <token>` is the paste path, like `join`. |
| `auth list` | tenants, live org membership, the active tenant, and token health |
| `auth switch <org>` | set the active (default) tenant |
| `auth whoami [--all]` | identity for the active tenant, or all of them |
| `auth logout [<org>]` | clear one tenant, the active one, or `--all` |

The non-interactive and CI path stays `SPOR_TOKEN`.

```sh
spor auth login --server https://graph.example.com
spor auth switch tidefall
```

### login

```
spor login [--web] [--server <url>] [--org <slug>]
```

**Mode:** remote

Alias of `spor auth login` (see [`auth`](#auth) for flags).
`spor login <url> <token>` still works as the paste path.

```sh
spor login --server https://graph.example.com
```

### migrate

```
spor migrate <url>
```

**Mode:** local · **Alias:** `push`

Commit the local graph home and push it to a git remote you own, such as a
private GitHub repository. The URL is remembered as `origin`, so later
pushes need no argument. Pure git plumbing — no server route is involved.

```sh
spor migrate git@github.com:tidefall/team-graph.git
```

### whoami

```
spor whoami [--all]
```

**Mode:** remote

Echo the identity the server binds to your token for the active tenant.
`--all` enumerates every stored tenant. In local mode it explains there is
no server identity. Alias of `spor auth whoami`.

```sh
spor whoami --all
```

### person

```
spor person create [<name>] [--email <e>] [--id person-x]
spor person list
```

**Mode:** local

Create the local `type: person` node the queue binds your git identity to —
the local, self-serve counterpart to the admin-gated [`invite`](/reference/cli/team-admin/#invite).
`create` seeds the title and email from the graph home's git identity
(`git config user.name` / `user.email`); `--email`, `--name`, and `--id`
override the seeded values. Idempotent: a re-run that finds a node already
bound to your git identity reports it and exits 0. In remote mode your
person node is server-managed (`spor whoami`).

```sh
spor person create 'Ines Duarte' --email ines@tidefall.example.com
```

### token

```
spor token create [--expires <Nd>] [--label <l>]
spor token list [--all]
spor token revoke <prefix> [--all]
```

**Mode:** remote

Create, list, and revoke your own personal access tokens (`spor_pat_`) for
CI and headless use — the self-serve twin of [`invite`](/reference/cli/team-admin/#invite),
which mints for others. Every subcommand needs a token bound to a person
identity (check `spor whoami`).

| Subcommand | What it does |
| --- | --- |
| `token create` | mint a PAT bound to you, shown in plaintext once; `--expires <Nd\|ISO>` sets the lifetime (default and max: 1 year), `--label` tags it |
| `token list` | your PATs by hash prefix, label, and expiry; `--all` lists the whole team's (admin) |
| `token revoke <prefix>` | revoke one of your PATs by hash prefix; `--all` revokes any token by prefix (admin) |

```sh
spor token create --expires 90d --label ci
```
