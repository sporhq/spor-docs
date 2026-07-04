---
title: Common CLI tasks
description: Task-first recipes for the spor CLI — each a short, paste-ready sequence linking into the full verb reference.
sidebar:
  order: 2
---

Use this page by starting with what you came to do. Each recipe is a short, paste-ready sequence; the full A-Z verb reference with every flag follows on the pages after this one, and each recipe links to the exact entries it uses.

## Initialize a repo

Use this when a repo should start carrying Spor context. This creates the local graph first, then wires Spor into Claude and opts this repo in.

```sh
spor init
spor install claude
spor enable
```

[`spor init`](/reference/cli/setup-and-identity/#init) creates the local graph home: a `nodes/` directory versioned by git. [`spor install`](/reference/cli/setup-and-identity/#install) wires Spor into the named host coding agent, and [`spor enable`](/reference/cli/repo-scoping/#enable) writes `{"enabled": true}` to the repo's committable `.spor.json`.

If your team already runs a shared server, sign in with [`spor join`](/reference/cli/setup-and-identity/#join) or [`spor auth login`](/reference/cli/setup-and-identity/#auth) instead of starting from a local graph.

## Capture a decision

Use this when a decision has landed and future work should see it — here, the tidefall team recording its billing retry decision. Include the rejected alternative when it matters, because dismissed approaches are part of the context.

```sh
spor add "We retry a failed card charge three times over two days, then email the customer to update billing details. A longer retry window was rejected: it delays that email past the next billing cycle."
```

[`spor add`](/reference/cli/writing-to-the-graph/#add) captures the sentence as one markdown file recording one fact, a **node**. In remote mode the server types and links it; in local mode Spor writes a validated node file, and you can add `--type decision` when you need to force the type locally.

## Ask a question

Use this when the graph does not answer something you need before continuing. The `--mention` value names the decision the question is about.

```sh
spor ask "Did the dunning email copy get updated for the three-attempt retry window?" --mention dec-tidefall-billing-retries
```

[`spor ask`](/reference/cli/writing-to-the-graph/#ask) files the question as work instead of letting it disappear from the session. In remote mode the server routes it to the steward of the closest related context; in local mode it writes an open question node that appears in `spor next`.

## Find your next item

Use this when you want the next useful item for the `billing` project, then want context before starting. The queue step finds the item; the briefing step gathers the nearby graph context for it.

```sh
spor next --project billing
spor brief task-tidefall-retry-emails
```

[`spor next`](/reference/cli/reading-the-graph/#next) shows open work ranked by graph signal and human-set priority, scoped here to the `billing` project. [`spor brief`](/reference/cli/repo-scoping/#brief) compiles a briefing for `task-tidefall-retry-emails` before you begin.

## Read a node

Use this when you know the node id and need to inspect what was decided or how it changed. This is the direct path for checking `dec-tidefall-billing-retries`.

```sh
spor get dec-tidefall-billing-retries
spor history dec-tidefall-billing-retries --limit 10
```

[`spor get`](/reference/cli/reading-the-graph/#get) prints the node's raw markdown; add `--json` when you also need structured links to other nodes, the graph's **edges**, and the revision used for updates. [`spor history`](/reference/cli/reading-the-graph/#history) shows recent revisions for the same node, including who changed it, when, and what changed.

## Correct bad context

Use this when a briefing keeps bringing in stale context or missing context that should be there. Here the follow-up task should stop citing the superseded legacy invoicing decision.

```sh
spor correct task-tidefall-retry-emails --exclude dec-tidefall-legacy-invoicing "The legacy invoicing decision predates the three-attempt retry window; the dunning-flow spec is authoritative."
```

[`spor correct`](/reference/cli/writing-to-the-graph/#correct) records a standing correction for future briefings whose scope includes `task-tidefall-retry-emails`. The `--exclude` flag drops `dec-tidefall-legacy-invoicing`, and the quoted text becomes guidance for why it should stay out.

## See recent changes

Use this when you need to see what changed recently before you pick work up. The date phrase can be anything git understands.

```sh
spor changes --since '12 hours ago' --project billing
```

[`spor changes`](/reference/cli/reading-the-graph/#changes) shows one recent entry per node, newest first, for the `billing` project. Each entry marks whether the newest change came from a person or from machine work such as capture, distill, or gardener activity.

## Export your data

Use this when you need a copy of the graph outside the current setup. The first command exports the current node files, and the second exports full history when you are connected to a remote graph.

```sh
spor export --gzip --out graph.tar.gz
spor export --history --out graph-history.bundle
```

[`spor export`](/reference/cli/reading-the-graph/#export) streams the graph's `nodes/` directory as a tarball in either mode; extracting it with `tar x` reproduces the node files byte for byte. `--history` is remote-only and writes a git bundle, so `git clone graph-history.bundle graph` reproduces the graph repository with commit provenance.

## Switch hosted orgs

Use this when you belong to more than one hosted organization and need to change which tenant the CLI talks to. Tokens are org-scoped, so switching orgs changes the active credential.

```sh
spor auth list
spor auth switch tidefall
spor whoami
```

[`spor auth`](/reference/cli/setup-and-identity/#auth) lists stored tenants, shows the active one, and switches to `tidefall`. [`spor whoami`](/reference/cli/setup-and-identity/#whoami) then prints the identity the server binds to your token for that active tenant.

## Diagnose a broken setup

Use this first when Spor feels quiet, stale, or disconnected. The CLI can still work while automatic context machinery is failing open, so the diagnostic commands make that state visible.

```sh
spor status
spor-hook doctor
```

[`spor status`](/reference/cli/setup-and-identity/#status) prints what the CLI actually resolved: mode, graph home, project slug, identity, and health. `spor-hook doctor` checks the automatic machinery, including server reachability, token validity, outbox depth, briefing freshness, and recent hook or distiller errors; the [Diagnostics](/reference/diagnostics/) page gives the fuller troubleshooting walk.
