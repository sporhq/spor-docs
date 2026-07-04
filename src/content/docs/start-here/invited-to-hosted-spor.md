---
title: I was invited to hosted Spor
description: Join a team graph, confirm your identity, make one capture, and enable a repo.
sidebar:
  order: 4
---

Use this path when your team already runs Spor and you have an invite, or
someone has told you one is coming. In remote mode the team shares one live
graph on a Spor server. Writes are attributed to the person or agent that
made them, and concurrent writes are handled server-side.

What the server can see, what reaches a model, and how to export everything
are stated precisely in [Data, privacy, and export](/hosted/data-privacy-and-export/).

:::note
The first request after your team's graph has been idle can take longer than
later requests. You do not need to retry immediately; see
[slow first request diagnostics](/reference/diagnostics/#slow-first-request-after-an-idle-period).
:::

## 1. Install the CLI

You need Node.js 20 or newer.

```bash
npm install -g @sporhq/spor
```

Check the install:

```bash
spor --help
```

You should see a usage listing that begins:

```text
spor — Spor client CLI
```

If the shell says `spor: command not found`, open a new terminal first. If it
is still missing, npm's global bin directory is not on your PATH.

## 2. Join with your invite token

If a team admin sent you a token (`spor_pat_...`), paste it:

```bash
spor join spor_pat_9f3kexampletoken
```

With no URL, `spor join` targets the hosted Spor service
(`https://api.sporhq.io`). For a server of your own, name it:

```bash
spor join https://spor.example.com spor_pat_9f3kexampletoken
```

`join` stores an org-scoped credential and confirms it against the server
before finishing. Credentials are keyed by server and org, so joining one org
never overwrites another.

If you do not have a pasted token, `spor auth login` signs you in with a
device code. It prints a short code and a URL, and you approve in any
browser, which works over SSH and on headless machines.

On success, `spor join` prints a line like:

```text
stored credential for tidefall @ https://api.sporhq.io as person-ines <ines@tidefall.example.com>
```

It then prints the path of the credential file it wrote.

- If you see `token rejected by https://api.sporhq.io (401) — not stored`,
  the token is mistyped, expired, or revoked; nothing was saved. Ask whoever
  sent it to mint a new one.
- If you see `note: could not reach … storing anyway`, the credential was
  stored but not confirmed; check the server URL and your network, then verify
  with `spor whoami`.

## 3. Verify who you are

```bash
spor whoami
```

This echoes the identity the server binds to your token: your name, person
node id, and email.

You should see:

```text
Ines Duarte (person-ines) <ines@tidefall.example.com>
```

The not-bound case prints exactly:

```text
⚠ token maps to no person node — routed questions and personal queue will be empty
```

That token authenticates, but routed questions and your personal queue have
no person to attach to; tell whoever minted it. If `spor whoami` says
`unauthenticated (token rejected)`, the token itself is bad; go back to
step 2.

## Check it worked

Run:

```sh
spor status
```

A healthy hosted login looks like:

```text
mode:     remote  (not enabled here — run /spor:onboard to set up, or 'spor enable' to opt in; hooks are a no-op)
project:  billing
server:   https://api.sporhq.io
health:   OK (214 nodes)
token:    present
identity: Ines Duarte (person-ines) <ines@tidefall.example.com>
node:     20.11.0 (>= 20 required, OK)
```

The success signals are `health: OK` with a node count and an `identity:`
line naming you. The `(not enabled here …)` note is expected until you enable
a repository in step 6.

- If you see `health:   AUTH FAILED (401) — token invalid, revoked, or expired`
  and `identity: unauthenticated (token rejected)`, re-run `spor join` with a
  fresh token, or sign in with `spor auth login`.
- If you see `health:   OFFLINE — could not reach server (fetch failed)`, the
  server URL is wrong or unreachable; check the URL you joined and your
  network.
- If this hangs or the first request is slow, the team graph may be waking
  from idle; wait rather than retrying. See the slow-first-request note at the
  top of this page.

Next step: make your first capture below.

## 4. Make your first capture

```bash
spor add "The dunning email templates still cite the single-retry policy. Agreed with Ines we sweep them before the rollout."
```

In remote mode you send prose and the server types the entry and links it
into the graph. You do not pick a type or write frontmatter. That capture
text is all the ingestion model sees; session transcripts stay on your
machine, as described in
[Data, privacy, and export](/hosted/data-privacy-and-export/).

A few seconds later the node is visible to the whole team.

## 5. Read the team queue

```bash
spor next
```

`spor next` now reads the shared queue, so the ranking reflects everyone's
open work, claims, and blockers, not just your own.

## 6. Enable a repository you work in

```bash
spor enable
```

You should see:

```text
enabled Spor for /home/ines/code/billing
  /home/ines/code/billing/.spor.json — hooks are now active here; commit it to share the setting
```

This writes `{"enabled": true}` to that repo's committable `.spor.json`.
Spor is opt-in per repository. A repo participates only once it is explicitly
enabled, so a side project never feeds the team graph by accident.

## What you now know

- Remote mode uses one live team graph on a Spor server.
- `spor join` stores an org-scoped credential and verifies it before use.
- `spor whoami` shows the person and org bound to your token.
- `spor enable` opts a repository into the team graph.

## Where to go next

- [What happens automatically](/use-spor/what-happens-automatically/) for
  what the plugin now does in every session in an enabled repo.
- [Connect an assistant](/start-here/connect-an-assistant/) to let claude.ai
  or Claude Code work with the same graph.
- [Hosted Spor](/hosted/) for organizations, sign-in, tokens, and how your
  data is handled.
