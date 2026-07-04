---
title: Connect an assistant
description: Add hosted or self-hosted Spor as an MCP connector for claude.ai or Claude Code.
sidebar:
  order: 5
---

Use this path when your team has hosted Spor, or a self-hosted Spor server,
and you want claude.ai or Claude Code to read and write the team graph.

## 1. Before you start

You need a personal access token (`spor_pat_...`). The consent step asks for
it once. If you do not have one, ask your server admin.

You give your assistant one URL: your server's MCP address. On hosted Spor,
use `mcp.sporhq.io`. On a server of your own, use its `/mcp` address, for
example `https://spor.example.com/mcp`.

## 2. Add the connector

In claude.ai, open **Settings → Connectors → Add custom connector**. Enter
the MCP URL, then click **Connect**. Your browser opens the Spor server's own
authorization page.

If you use Claude Code instead of claude.ai, add the server as a remote HTTP
connector:

```bash
claude mcp add --transport http spor https://spor.example.com/mcp
```

On first use Claude Code prompts you to authenticate. You can also run `/mcp`
and select the server. The same browser flow opens.

## 3. Approve access

Sign in on the Spor server's own page. On hosted Spor, use your organization
account.

The authorize page asks you to paste your `spor_pat_...` token once. The
token is submitted to the Spor server's own page and never reaches the
connector host. It is how the server knows which person this grant acts as,
so everything the assistant writes is attributed to you.

If you belong to more than one organization, pick the one this connector
should work against. After that, the host holds short-lived OAuth credentials
of its own, not your token.

## 4. Check it worked

Ask the assistant:

```text
what's in my Spor queue?
```

You should see the host call a Spor tool and answer with ranked queue items:
node ids like `issue-tidefall-double-charge` with one-line summaries.

Once connected, it can search the graph, read the ranked queue, and record
outcomes back. Each write is attributed to you.

- If Spor does not appear in the host's connector or tool list, the connector
  was not added or the URL is wrong; a self-hosted server needs the `/mcp`
  path. In Claude Code, run `/mcp` to see the server and its authentication
  state.
- If this says unauthorized, or the tools start failing after working before,
  the grant expired or was revoked; remove the connector and add it again to
  re-authorize, and check that your `spor_pat_...` token is still valid
  (`spor token list`).
- If this hangs on the first use, a hosted team graph may be waking from idle;
  wait rather than retrying. See
  [slow first request diagnostics](/reference/diagnostics/#slow-first-request-after-an-idle-period).
- If the assistant answers from general knowledge without calling any tool,
  the connector's tools are disabled for that conversation; enable them in the
  chat's tool settings.

Next step: setup is complete. The links under Where to go next cover the
operating loop and the tools the assistant can call.

## 5. Disconnecting

Removing the connector from the host's settings ends that grant and nothing
else. Your personal access token and other connected assistants keep working.
The full credential lifecycle, including revoking the token itself, is in
[Tokens and access](/hosted/tokens-and-access/).

## What you now know

- A connected assistant needs one MCP URL and a one-time token consent flow.
- Your `spor_pat_...` token is submitted to the Spor server, not the
  connector host.
- Assistant writes are attributed to the person represented by the token.
- Removing one connector ends that grant without revoking your token.

## Where to go next

- [MCP operating loop](/reference/mcp/operating-loop/) for the loop the server
  teaches a connected assistant.
- [MCP tools](/reference/mcp/tools/) for every tool the assistant can call.
- [Tokens and access](/hosted/tokens-and-access/) for tokens, grants, and
  revocation.
