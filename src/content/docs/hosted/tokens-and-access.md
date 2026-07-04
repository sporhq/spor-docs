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

Check the first two commands before you move on. `spor token create` prints
the minted token once:

```text
minted personal access token for Ines Duarte (person-ines) <ines@tidefall.example.com> [laptop] (expires 2026-10-02T09:15:00.000Z) [a1b2c3d4e5f6]
  this is shown ONCE — copy it now, it is not recoverable:

  spor_pat_...
```

`spor token list` then shows it by hash prefix and label:

```text
a1b2c3d4e5f6  laptop  (expires 2026-10-02T09:15:00.000Z)
```

An expired token is flagged `EXPIRED` in the listing.

- If you see `no personal access tokens — mint one with 'spor token create'`,
  the list is empty. That is the expected first-time state, not an error.
- If you see
  `forbidden — a personal access token needs a bound person identity.`, your
  current token maps to no person node; check `spor whoami` and ask an admin
  to fix the binding.
- If you see `mint failed (401)`, the credential you are calling with is
  itself invalid, revoked, or expired; sign in again with `spor auth login`
  before minting.

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
grants instead: an access token (`spor_oat_…`) good for 30 days and a
refresh token (`spor_ort_…`) good for 90 days that rotates on each use, both
minted through the authorization flow at `auth.sporhq.io`. Authorization
codes are single-use and expire after 10 minutes. A grant carries the same
identity and the same flat read/write scope as the token it was authorized
with — the connector is you, as far as attribution is concerned. The exact
flows, endpoints, and lifetimes are specified in
[Authentication](/reference/api/authentication/).

Grants can be revoked independently of your tokens, with two levers of very
different blast radius:

- **Revoke one grant.** `POST /oauth/revoke` with the connector's token is
  token-scoped — it ends that grant and nothing else. Your personal access
  token and any other connected assistants keep working. Removing the
  connector from the host's settings is the everyday way to trigger this.
- **Revoke the personal access token.** `spor token revoke` (or
  `DELETE /v1/me/tokens/{hash-prefix}`) cascades the safe direction: it
  revokes the PAT itself and every OAuth grant that was authorized with it,
  so killing the token really kills the access. Reach for this when the
  token itself may be compromised, not to disconnect a single host. The
  cascade is visible in the output:
  `revoked a1b2c3d4e5f6 (+2 oauth grants)`.

Admins have a matching offboarding revoke for any token; the same cascade
applies, so an admin removing a person's token also disconnects that
person's connectors.

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
