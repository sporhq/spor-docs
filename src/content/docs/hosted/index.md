---
title: Hosted Spor
description: One shared graph per organization, on the same CLI, API, and MCP surface as local mode.
sidebar:
  order: 1
---

Hosted Spor is the team version of the graph you run locally. Your
organization gets one shared graph on the Spor server, running isolated from
every other organization's, and everyone on the team reads and writes the same
nodes through the surfaces you already use: the `spor` CLI, the REST API, and
the MCP connector. Nothing about the node format or the tools changes between
local mode and hosted — what changes is that the graph is multiplayer, every
write is attributed to the person or agent token that made it, and your data
stays exportable in full (history included) at any time.

## The hostnames

You will touch four hostnames:

| Host | What it is |
|---|---|
| `app.sporhq.io` | The web app |
| `api.sporhq.io` | The REST API — what the CLI and the web app talk to |
| `mcp.sporhq.io` | The MCP connector, for claude.ai and other MCP hosts |
| `auth.sporhq.io` | Sign-in and OAuth |

A team-scoped token routes each request to your organization's graph, so the
same hostnames serve every organization without any of them seeing another's
data.

## Where to start

What the service can see and how you get your data out are stated in
[Data, privacy, and export](/hosted/data-privacy-and-export/); read it
before you connect anything.

Joining is by invitation: an admin on your team invites you, you sign in at
the hosted front door with your email, and your account becomes a member of
the organization. From there:

1. **Sign in** — see [Organizations and sign-in](/hosted/organizations-and-sign-in/).
2. **Connect your tools** — point the CLI at `api.sporhq.io` and add the
   claude.ai connector; see [Connecting your tools](/hosted/connecting-your-tools/).
3. **Work normally.** Queries, captures, the queue, and lenses behave exactly
   as in local mode, except your teammates' writes show up too.

The first request after an idle period can take longer than later requests. If
that keeps happening, see
[slow first request diagnostics](/reference/diagnostics/#slow-first-request-after-an-idle-period)
for what to check.

## The rest of this section

- [Organizations and sign-in](/hosted/organizations-and-sign-in/) — invitations, multi-org accounts, switching.
- [Connecting your tools](/hosted/connecting-your-tools/) — CLI configuration and the MCP connector.
- [Tokens and access](/hosted/tokens-and-access/) — personal access tokens, OAuth grants, admin management.
- [Agents and attribution](/hosted/agents-and-attribution/) — agent identities and the audit trail.
- [Data, privacy, and export](/hosted/data-privacy-and-export/) — what the server and its model can see, full export, and revoking access.
- [Admin reference](/hosted/admin-reference/) — invitations, identity binding, token management, and org administration from the admin's seat.
