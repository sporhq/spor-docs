---
title: Team administration
description: Mint teammate tokens and run ops-facing operations against a team server.
sidebar:
  order: 4
---

Two verbs, both remote, both admin-oriented: `invite` brings a teammate into
the graph, and `admin` collects the ops-facing operations kept apart from
everyday graph work. Everyday self-serve token management is
[`spor token`](/reference/cli/setup-and-identity/#token).

### invite

```
spor invite --person <id> | --name <n> --email <e> [--id <id>] [--expires <Nd>]
```

**Mode:** remote (admin token)

Mint a person-bound token and print a paste-ready `spor join` line. Pass
`--person` to bind an existing person node, or `--name`/`--email` to create
the node first (`--id` names it explicitly). `--expires` sets the token
lifetime.

```bash
spor invite --name 'Jo Diaz' --email jo@example.com --expires 30d
```

### admin

```
spor admin gardener [--json]
spor admin token list
spor admin token revoke <prefix>
```

**Mode:** remote

Ops-facing operations the server owns.

`admin gardener` runs a gardener sweep now. The sweep files its observations
as `type: finding` queue items and resolves its own findings whose condition
has cleared; it never mutates human-authored nodes. It can examine the whole
graph, so an on-demand run may take a while. `--json` prints the raw
`{checked, filed, resolved, skipped}` envelope. The sweep endpoint is
authenticated but not admin-gated today, so any valid team token can run it;
a 403 means the deployment added the gate and admin privilege is required
(check `spor whoami` for `is_admin`).

`admin token list` and `admin token revoke <prefix>` are the team-wide,
admin-gated forms of `spor token list --all` and
`spor token revoke <prefix> --all`.

```bash
spor admin gardener --json
spor admin token revoke a1b2c3
```
