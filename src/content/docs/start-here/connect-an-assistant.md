---
title: Connect an AI assistant
description: Add the Spor connector in claude.ai or Claude Code, complete the OAuth flow, and revoke access safely.
sidebar:
  order: 6
---

The Spor server speaks MCP over Streamable HTTP at `/mcp`, with the standard
OAuth 2.1 discovery chain a connector host expects: protected-resource
metadata (RFC 9728, advertised on the first unauthenticated request),
authorization-server metadata (RFC 8414), dynamic client registration
(RFC 7591), and authorization-code + PKCE. In practice this means you give
your host one URL and it works out the rest.

Before you start, have your personal access token (`spor_pat_…`) at hand —
the consent step asks for it once. If you don't have one, ask your server
admin.

## claude.ai and Cowork

1. Open **Settings → Connectors → Add custom connector**.
2. Enter your server's MCP URL, for example
   `https://spor.example.com/mcp`.
3. Click **Connect**. Your browser opens the Spor server's own authorization
   page.
4. Complete the flow described below, then return to the host. The Spor tools
   appear in the assistant's tool list.

## Claude Code

Add the server as a remote HTTP connector, then authenticate:

```bash
claude mcp add --transport http spor https://spor.example.com/mcp
```

On first use Claude Code prompts you to authenticate (or run `/mcp` and
select the server); the same browser flow below opens. Consult your host's
documentation for the current command syntax — the server side is just the
one URL.

## The OAuth flow you'll see

The authorization runs entirely on the Spor server's own pages:

1. **Sign in.** On hosted Spor you sign in through the front door with your
   organization account.
2. **Consent — a token exchange.** The authorize page asks you to paste your
   existing `spor_pat_…` personal access token. The token is submitted to the
   Spor server's own page and **never reaches the connector host**; it is how
   the server knows which person this grant acts as. The resulting OAuth
   identity is exactly your token's `{name, email}` attribution record, so
   everything the assistant writes is attributed to you.
3. **Organization selection.** If you belong to more than one organization,
   pick the one this connector should work against; the grant is scoped to it.

The host then holds short-lived OAuth credentials, not your token: access
tokens (`spor_oat_…`) live 30 days, refresh tokens (`spor_ort_…`) live 90
days and rotate on each use. Authorization codes are single-use and expire
after 10 minutes. Unauthenticated MCP calls are always rejected — there is no
anonymous author.

## Revoking access

Two levers, with very different blast radii:

- **Disconnect one assistant (recommended): revoke the grant's token.**
  `POST /oauth/revoke` with the connector's token is **token-scoped** — it
  ends that grant and nothing else. Your personal access token and any other
  connected assistants keep working. Removing the connector from the host's
  settings is the everyday way to trigger this.
- **Revoke your personal access token (wholesale).** `spor token revoke` (or
  `DELETE /v1/me/tokens/{hash-prefix}`) revokes the PAT itself **and cascades
  to every OAuth grant minted from it** — every assistant you connected with
  that token is signed out at once. Reach for this when the token itself may
  be compromised, not to disconnect a single host.

Admins have a matching offboarding revoke for any token; the same cascade
applies, so an admin removing a person's token also disconnects that person's
connectors.
