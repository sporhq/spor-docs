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

```sh
npm install -g @sporhq/spor
```

Check the install:

```sh
spor --help
```

You should see a usage listing that begins:

```text
spor — Spor client CLI
```

If the shell says `spor: command not found`, open a new terminal first. If it
is still missing, npm's global bin directory is not on your PATH.

## 2. Sign in

```sh
spor auth login
```

This is how you authenticate to hosted Spor. It signs you in with a device
code: the CLI prints a short code and a URL, and you approve in any browser,
including one on a different machine — so it works over SSH and on headless
boxes.

```text
To sign in, open this URL in a browser:
  https://api.sporhq.io/device?user_code=TQDN-KRXB
and enter the code:  TQDN-KRXB

Waiting for approval (Ctrl-C to cancel)…
```

If this machine has a browser, the CLI opens that URL for you; `--no-open`
stops it from trying. In the browser you sign in and, if you belong to more
than one organization, pick the one to sign in to. The terminal continues on
its own once you approve.

With no server named, `spor auth login` targets the hosted Spor service
(`https://api.sporhq.io`). For a server of your own, name it:

```sh
spor auth login --server https://spor.example.com
```

On success the CLI prints the credential it stored, the file it wrote, and
the tenant it made active:

```text
stored credential for tidefall @ https://api.sporhq.io as person-ines <ines@tidefall.example.com>
  /home/ines/.spor/auth/credentials.json
  active tenant: https://api.sporhq.io/tidefall
```

Credentials are keyed by server and org, so signing in to one org never
overwrites another. Sign in to a second org with
`spor auth login --org <slug>`, and switch between them with
`spor auth switch <org>`.

- If you see `offline — could not reach https://api.sporhq.io (fetch failed)`,
  the server URL is wrong or unreachable; check the URL and your network.
- If you see `the code expired before approval` or
  `timed out waiting for approval`, the code has a time limit and it ran out;
  run `spor auth login` again and approve promptly.
- If you see `authorization was denied.`, the approval was rejected in the
  browser — usually the wrong account or organization. Run it again and
  approve as the person who was invited.

:::note[If someone handed you a token instead]
Some teams paste a personal access token (`spor_pat_...`) out of band. Store
one with `spor join spor_pat_9f3kexampletoken` (or
`spor join https://spor.example.com spor_pat_9f3kexampletoken` for your own
server); it confirms the token against the server before saving, and prints
`token rejected by https://api.sporhq.io (401) — not stored` if the token is
mistyped, expired, or revoked. This is also the path for CI, which uses the
`SPOR_TOKEN` environment variable. For everyday use on your own machine,
`spor auth login` is the way in. See
[Tokens and access](/hosted/tokens-and-access/).
:::

## 3. Verify who you are

```sh
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

Your credential authenticates, but routed questions and your personal queue
have no person to attach to; tell whoever set up your account. If
`spor whoami` says `unauthenticated (token rejected)`, the credential itself
is bad; sign in again from step 2.

## Check it worked

Run:

```sh
spor status
```

A healthy hosted login looks like:

```text
mode:     remote  (not enabled here — run /spor:onboard to set up, or 'spor enable' to opt in; hooks are a no-op)
repo:     billing
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
  and `identity: unauthenticated (token rejected)`, your credential has
  expired or been revoked; run `spor auth login` again.
- If you see `health:   OFFLINE — could not reach server (fetch failed)`, the
  server URL is wrong or unreachable; check the server URL and your
  network.
- If this hangs or the first request is slow, the team graph may be waking
  from idle; wait rather than retrying. See the slow-first-request note at the
  top of this page.

Next step: make your first capture below.

## 4. Make your first capture

```sh
spor add "The dunning email templates still cite the single-retry policy. Agreed with Ines we sweep them before the rollout."
```

In remote mode you send prose and the server types the entry and links it
into the graph. You do not pick a type or write frontmatter. That capture
text is all the ingestion model sees; session transcripts stay on your
machine, as described in
[Data, privacy, and export](/hosted/data-privacy-and-export/).

A few seconds later the node is visible to the whole team.

## 5. Read the team queue

```sh
spor next
```

`spor next` now reads the shared queue, so the ranking reflects everyone's
open work, claims, and blockers, not just your own.

## 6. Enable a repository you work in

```sh
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
- `spor auth login` signs you in with a device code and stores an org-scoped
  credential, one per organization.
- `spor whoami` shows the person bound to your token — name, person node id,
  and email.
- `spor enable` opts a repository into the team graph.

## Where to go next

- [What happens automatically](/use-spor/what-happens-automatically/) for
  what the plugin now does in every session in an enabled repo.
- [Connect an assistant](/start-here/connect-an-assistant/) to let claude.ai
  or Claude Code work with the same graph.
- [Hosted Spor](/hosted/) for organizations, sign-in, tokens, and how your
  data is handled.
