---
title: Authentication
description: Personal access tokens, OAuth 2.1 for connectors, the device grant, agent tokens, render tickets, and the admin gate.
sidebar:
  order: 2
---

Every route requires a bearer token:

```
Authorization: Bearer spor_pat_...
```

Transport is HTTPS only. Unauthenticated calls are hard-rejected on both the
REST and MCP surfaces — there is no anonymous author. Tokens grant full read
and write: the trust model is "everyone on the team can read and write the
team graph", the same as a shared repository. The one privileged distinction
is the [admin gate](#the-admin-gate).

## Personal access tokens

Per-user tokens carry the `spor_pat_` prefix (legacy `sub_pat_` tokens stay
valid, no re-mint required). A token's canonical subject is a **person node**
in the graph, and its `{name, email}` attribution resolves from that node at
read time — an email change re-points the token instead of severing it.

A token may carry an expiry; once past it, the token is rejected like a
revoked one.

Three ways to mint one:

- **Self-serve**: `POST /v1/me/tokens` mints a token bound to your own
  person node. See [Tokens and agents](/reference/api/tokens-and-agents/).
- **Admin onboarding**: `POST /v1/admin/tokens` binds a token to someone
  else's person node.
- **Server box**: an operator runs `spor-mint-token --person <person-node-id>`
  directly on the server; `--expires <N>d|<date>` sets an expiry.

Check what a token resolves to with `GET /v1/me`
([Reads](/reference/api/reads/#get-v1me)). A response with `bound: false` means the
token authenticates but maps to no person node, so routed questions and the
personal queue will be empty.

## The admin gate

A caller is an admin if and only if their person node carries a `stewards`
edge to the graph root (default `org-root`). Without it, the admin routes
(`/v1/admin/*`, the `?auth=1` export) return `403 forbidden`. The first admin
is bootstrapped on the server box with `spor-mint-token --admin --person <id>`,
which writes that `stewards` edge, creating the person node from
`--name`/`--email` if needed.

## OAuth 2.1 for MCP connectors

Connector hosts (such as claude.ai) cannot carry a static bearer token, so
the MCP surface supports the standard OAuth 2.1 discovery chain:

- **Protected-resource metadata** (RFC 9728), advertised on the `/mcp` 401
  via `WWW-Authenticate`.
- **Authorization-server metadata** (RFC 8414).
- **Dynamic client registration** (RFC 7591).
- **Authorization code + PKCE**, S256 only, public clients.

The consent step is a **PAT exchange**: the authorize page asks you to paste
your existing `spor_pat_` token into the server's own page. The token never
reaches the connector host, so the OAuth identity is exactly the PAT's
`{name, email}` attribution record.

Token lifetimes:

| Token | Prefix | Lifetime |
|---|---|---|
| Access token | `spor_oat_` (legacy `sub_oat_` accepted) | 30 days |
| Refresh token | `spor_ort_` | 90 days, rotating, single-use |
| Authorization code | — | single-use, 10 minutes |

A client holding a refresh token transparently refreshes on a 401/403
(`grant_type=refresh_token`) and retries once.

## CLI sign-in: the device grant

`spor auth login` (alias `spor login`) defaults to the OAuth 2.0 device
authorization grant (RFC 8628), so it works headless and over SSH:

1. The CLI calls `POST /oauth/device_authorization {client_id?, scope?}` and
   receives `{device_code, user_code, verification_uri,
   verification_uri_complete, expires_in, interval}`.
2. It prints the URL and code (auto-opening a local browser when one is
   present); you approve in any browser.
3. It polls `POST /oauth/token {grant_type:
   urn:ietf:params:oauth:grant-type:device_code, device_code}` — answering
   `authorization_pending`/`slow_down` until approval — then receives the
   same person-bound, org-scoped, refreshable `spor_oat_`/`spor_ort_` pair
   the connector flow mints.

### Loopback PKCE

`spor auth login --web` is the optimization for when a browser runs on the
same machine (OAuth 2.1 authorization code + PKCE, RFC 8252). The CLI binds a
one-shot `http://127.0.0.1:<port>/callback` listener, anonymously registers a
public client for it (`POST /oauth/register`, RFC 7591), opens the browser to
`GET /oauth/authorize` with `response_type=code`, `client_id`,
`redirect_uri`, `code_challenge`, `code_challenge_method=S256`, `state`, and
optional `scope`, captures the redirected `?code` (CSRF-checked against
`state`), and exchanges it at `POST /oauth/token {grant_type:
authorization_code, code, code_verifier, client_id, redirect_uri}` for the
same token pair. It then best-effort unregisters the throwaway client
(RFC 7592 `DELETE`), and falls back to the device grant when the server
exposes no loopback or registration endpoints.

`spor auth login <url> <token>` / `spor join <url> <token>` is the
non-interactive paste path; CI stays on `SPOR_TOKEN`.

## Agent session tokens

A person mints a short-lived, per-session token for an agent they **own**
through `POST /v1/agents/{id}/token`
([Tokens and agents](/reference/api/tokens-and-agents/)). Authorization is ownership
(the agent's `owned-by → person` edge), never admin, so running your own
agents needs no special privilege.

The token's record carries `{agent, session}` and no person; the owning
person resolves from the `owned-by` edge at verify time, so a deleted agent
or owner makes the token fail closed rather than impersonate. Writes under it
are attributed **agent on behalf of person**: the server stamps
`authored_by_agent` and `session` alongside the owner as `author`, and uses
`authored_via: dispatch` — the `person → agent` chain is the audit trail.

The token can be minted **session-deferred** (the run session is not known
until the run exists) and bound to the real session afterwards via
`POST /v1/agents/session` — write-once, so the binding is always the actual
run. Writes before the bind carry no session rather than a phantom one. A
long-lived **standing** variant (`{standing: true}`) mints a durable
agent-scoped `spor_pat_` for headless environments.

## Render tickets

`POST /v1/lens/{id}/ticket` mints a signed, expiring, **read-only** ticket
carrying `{lens_id, sharer_person_id, exp}` — the credential a shared view
link carries instead of the sharer's PAT. It binds the viewer to the recorded
sharer (the render shows a "Viewing as" banner), is honored only on
`GET /v1/lens/{id}/render`, and can never authorize a write. Tickets are
stateless (HMAC over a server-held key): there is no revocation list; expiry
is the bound. See [Lenses and sharing](/reference/api/lenses-and-sharing/).
