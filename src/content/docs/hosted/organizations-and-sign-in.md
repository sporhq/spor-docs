---
title: Organizations and sign-in
description: Membership by invitation, accounts that span organizations, and switching between them.
sidebar:
  order: 2
---

An organization is the unit of everything in hosted Spor: one shared graph,
one membership list, one isolation boundary. You join one by invitation — an
admin on the team invites you, and you sign in through the hosted front door
at `auth.sporhq.io` with your email. There is no open signup into an existing
organization's graph. See
[Data, privacy, and export](/hosted/data-privacy-and-export/) for what the
hosted service can see and how data leaves it.

## One account, several organizations

An account can belong to more than one organization — a common shape for
contractors, or for anyone who keeps a personal graph alongside a team one.
Your credentials are org-scoped: each token routes to exactly one
organization's graph, so holding memberships in two organizations means
holding two credentials, and the CLI stores them side by side rather than
overwriting one with the other.

The CLI manages this for you:

```bash
spor auth list            # your organizations, which is active, token health
spor auth switch acme     # make a different organization the active one
spor auth whoami          # who the active credential says you are
spor auth logout acme     # drop one organization's credential (or --all)
```

`spor auth list` does a live membership check against the server
(`GET /v1/me/org-choices`), so an organization you were added to — or removed
from — since your last sign-in shows up without re-authenticating. If the
server cannot enumerate your memberships, the CLI falls back to what it has
cached rather than failing.

Signing in to a second organization is just another `spor auth login` (or
`spor join`); it adds a credential, it never replaces the first. When
scripting or in CI, `SPOR_ORG` selects among stored credentials explicitly —
see [Connecting your tools](/hosted/connecting-your-tools/) for the full
configuration picture.

## Identity inside the graph

Signing in gives you an account; being useful in the graph requires a
**person node** — the node your writes are attributed to, that questions get
routed to, and that your personal queue is keyed on. Invitation normally sets
this up. If a token authenticates but maps to no person node, the server
reports it (`bound: false` on `GET /v1/me`) and the CLI warns, because routed
questions and your personal queue would silently come back empty. If you see
that warning, ask your admin to bind your identity.

Whether you are an admin is also a fact in the graph, not a separate role
system: admins are the people with a stewardship edge to the organization's
root node, and only they can reach the admin surfaces described in
[Tokens and access](/hosted/tokens-and-access/).
