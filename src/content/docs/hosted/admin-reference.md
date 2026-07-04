---
title: Admin reference
description: Invitations, identity binding, token management, and org administration from the admin's seat, linking into the full CLI and API references.
sidebar:
  order: 7
---

This page is for organization admins on hosted Spor. Admin is a graph fact:
the admins are the people holding a `stewards` edge from their person node to
the organization's root node. Provider roles and email domains confer no admin
authority.

The trust model is otherwise flat. A team token grants full read and write on
the team graph; admin gating is the exception, not the default, and this page
covers the admin-facing surfaces (a metrics export endpoint is also
admin-gated — see [API reads](/reference/api/reads/#get-v1metricscapture)).
`spor whoami` reports whether the server considers the current token an admin
through `is_admin`.

## Invite a teammate

`spor invite` mints a person-bound token and prints a paste-ready `spor join`
line for the teammate. It is a remote-mode command and needs an admin token.

```sh
spor invite --name 'Marek Ilves' --email marek@tidefall.example.com --expires 30d
```

Use `--person <id>` to bind an existing person node, or `--name` and
`--email` to create the person node first. The full command entry is in
[Team administration](/reference/cli/team-admin/#invite).

Good onboarding is three deliberate steps: author the person node, add their
`stewards` edges, and mint the token bound to the node. The invite command can
create the person node, but it does not replace thinking about stewardship.
Skip the `stewards` edges and questions in that person's area route to no one.
See [Identity and attribution](/use-spor/identity/) and
[Ask and answer questions](/use-spor/ask-and-answer-questions/).

The invitee's path is covered in
[I was invited to hosted Spor](/start-here/invited-to-hosted-spor/). The REST
twin is `POST /v1/admin/tokens`, which mints a token bound to someone else's
person node; see [Tokens and agents](/reference/api/tokens-and-agents/).

## Fix an unbound identity

If a token authenticates but maps to no person node, `GET /v1/me` reports
`bound: false` and the CLI warns. Routed questions and that person's personal
queue come back empty until an admin gives them a token bound to the right
person node.

Use the invitation path above, or mint a person-bound token with
`POST /v1/admin/tokens`. The admin gate for these endpoints is described in
[Authentication](/reference/api/authentication/).

## Manage tokens

Everyday token management is self-serve:

```sh
spor token create
spor token list
spor token revoke <prefix>
```

Each member manages their own tokens. See the
[`token` CLI reference](/reference/cli/setup-and-identity/#token) and
[Tokens and access](/hosted/tokens-and-access/) for the member-facing path.

Admins get the team-wide forms:

```sh
spor admin token list
spor admin token revoke <prefix>
```

The equivalent commands are `spor token list --all` and
`spor token revoke <prefix> --all`. The endpoints live under
`/v1/admin/tokens`; non-admin callers get `403`.

Listings show hash prefixes and metadata only. The server keeps only a hash
and cannot show plaintext it never stored.

Revoking a personal access token also revokes every OAuth grant authorized
with it. That cascade is the offboarding move: an admin revoking a departing
member's token also disconnects that person's connected assistants.

## Agents

Agents are person-owned and self-serve. Members create and manage their own
agents; see [Agents and attribution](/hosted/agents-and-attribution/).

The admin extras are API surfaces: `GET /v1/agents?all=1` lists every agent in
the organization, `POST /v1/admin/agents` creates an agent on behalf of
another person, and `GET /v1/profiles/{id}/hosts` shows an admin the whole
host fleet where an ordinary member sees only their own boxes. Full endpoint
detail is in [Tokens and agents](/reference/api/tokens-and-agents/).

## Run a gardener sweep

`spor admin gardener` runs a gardener sweep now.

```sh
spor admin gardener
```

The sweep files its observations as `type: finding` queue items and resolves
its own findings whose condition has cleared. It never mutates human-authored
nodes. The full verb entry, including the gating caveat, is in
[Team administration](/reference/cli/team-admin/#admin).

## Export data

`spor export --history` writes a git bundle of the whole graph repository with
full commit provenance. This is the data-exit path and is available to any
member.

`spor export --auth` is the admin-gated form that also bundles the credential
set for disaster restore.

See [Data, privacy, and export](/hosted/data-privacy-and-export/) and the
[`export` CLI reference](/reference/cli/reading-the-graph/#export).
