---
title: Hosted quickstart
description: Join a team graph with an invite token or a device-code sign-in, and make your first capture against it.
sidebar:
  order: 5
---

In remote mode your team shares one live graph on a Spor server. Writes are
attributed to the person or agent that made them, and concurrent writes are
handled server-side so teammates do not clobber each other. This quickstart
assumes you have [installed the CLI](/start-here/install/) and that your
team already has a graph — either on the hosted Spor service or on a server
of its own.

:::note
The first request after your team's graph has been idle can take longer than
later requests. You do not need to retry immediately; see
[slow first request diagnostics](/reference/diagnostics/#slow-first-request-after-an-idle-period).
:::

## Join with an invite token

If a team admin sent you a token (`spor_pat_...`), paste it:

```bash
spor join spor_pat_9f3kexampletoken
```

With no URL, `spor join` targets the hosted Spor service
(`https://api.sporhq.io`). To join a graph on another server, name it:

```bash
spor join https://spor.example.com spor_pat_9f3kexampletoken
```

`join` stores an org-scoped credential and confirms it against the server
before finishing. Credentials are keyed by server and org, so if you belong
to several orgs you hold several credentials — joining one never overwrites
another.

## Or sign in interactively

Without a pasted token, sign in with:

```bash
spor auth login
```

The default is a device-code flow: it prints a short code and a URL, and you
approve the sign-in in any browser — this works over SSH and on headless
machines. On a machine with a local browser, `--web` uses a loopback browser
flow instead. `--server <url>` names the server and `--org <slug>` labels the
credential when you belong to more than one org.

## Verify who you are

```bash
spor whoami
```

This echoes the identity the server binds to your token — your person node,
name, and org. If it reports that the token is not bound to a person, tell
whoever minted it: an unbound token authenticates but gets an empty personal
queue. `spor auth list` shows every stored credential, and
`spor auth switch <org>` picks the active one.

## Pointing at your org

`spor join` and `spor auth login` store everything the CLI needs. For CI or
other non-interactive environments, the environment variables do the same
job:

```bash
export SPOR_SERVER=https://api.sporhq.io
export SPOR_TOKEN=spor_pat_9f3kexampletoken
export SPOR_ORG=harbor        # selects a stored org when you have several
```

Setting `SPOR_SERVER` is what resolves the CLI into remote mode; `spor
status` confirms the resolved mode, server, and identity.

## First capture and the team queue

```bash
spor add "Retry-After is missing from 429 responses on the export API. \
Agreed with Priya we fix it before the beta."
```

In remote mode you send prose and the server's ingestion model types the
node and links it into the graph — you do not pick a type or write
frontmatter. A few seconds later it is visible to the whole team:

```bash
spor next
```

`spor next` now reads the shared queue, so the ranking reflects everyone's
open work, claims, and blockers, not just your own.

:::tip
There is also a Spor connector for claude.ai, so the same team graph is
readable and writable from chat sessions, not only from the CLI and coding
agents. See the [MCP section](/reference/mcp/) for setup.
:::

## Next

Run `spor enable` in each repository that should feed and read the team
graph, then see
[what happens automatically](/start-here/what-happens-automatically/)
in a wired session.
