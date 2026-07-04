---
title: Tokens and access
description: Personal access tokens, OAuth grants, and the admin surface for managing both.
sidebar:
  order: 4
---

Every request to hosted Spor carries a credential, and every credential
resolves to an identity in the graph. The trust model is deliberately flat:
a team token grants full read and write on the team graph, the same way a
shared repository does. The one privileged distinction is **admin** — the
people holding a stewardship edge to the organization's root node — which
gates the team-wide token management described at the end of this page.

This page covers what the credentials are and how their lifecycle works; the
exact request and response shapes live in the [API reference](/reference/api/).

## Personal access tokens

A personal access token (`spor_pat_...`) is bound to your person node, so
everything written under it is attributed to you. You manage your own without
any admin involvement:

```bash
spor token create --expires 90d --label "laptop"
spor token list
spor token revoke <hash-prefix>
```

Three properties to know:

- **The plaintext is shown once**, at creation. The server keeps only a hash;
  listings identify tokens by hash prefix plus your label, never the token
  itself.
- **Expiry is bounded.** You choose an expiry (a duration like `90d` or a
  date); it defaults to a year and cannot exceed a year — a longer request is
  rejected outright rather than silently shortened. An expired token is
  refused exactly like a revoked one.
- **Attribution follows your person node**, not a snapshot. If your email
  changes on your person node, existing tokens re-point to the updated
  identity instead of being severed.

## OAuth grants

Connectors such as claude.ai cannot carry a static token, so they hold OAuth
grants instead: an access token good for 30 days and a rotating, single-use
refresh token, both minted through the authorization flow at
`auth.sporhq.io`. A grant carries the same identity and the same flat
read/write scope as the token it was authorized with — the connector is you,
as far as attribution is concerned.

Grants can be revoked independently of your tokens, and the cascade runs the
safe direction: revoking a personal access token also revokes every OAuth
grant that was authorized with it, so killing the token really kills the
access.

## Admin token management

Admins get the team-wide view of the same machinery: list every member's
tokens (hash prefixes and metadata only — the server cannot show plaintext it
never stored), mint a token bound to someone else's person node (this is what
`spor invite` does during onboarding), and revoke any token during
offboarding or a suspected leak. The endpoints live under `/v1/admin/tokens`;
non-admin callers get a `403`.

The admin check itself is a graph fact — a `stewards` edge from the person
node to the organization root — so who holds it is as auditable as any other
edge.
