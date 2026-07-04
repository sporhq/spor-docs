---
title: Diagnostics
description: spor status, spor-hook doctor, the offline outbox, and what a slow first request after an idle period means.
---

**Use this when** something is unclear: no briefing appeared, a capture seems
lost, you are not sure which graph you are writing to, or the first request
after idle is slow.

**You do not need this if** everything behaves and you want to learn the
everyday loop; start with [Use Spor](/use-spor/).

**After reading this, you should be able to** choose between `spor status`
and `spor-hook doctor`, drain the offline outbox, and know when a slow first
request only needs time.

When something is unclear — no briefing appeared, a capture seems lost, you
are not sure which graph you are writing to — start with `spor status` and
`spor-hook doctor`. This page also covers the offline outbox, drained with
`spor drain`, and the slow first request after an idle period.

## spor status

```sh
spor status
```

The first thing to run. It prints what the CLI actually resolved from your
flags, environment, and config files: the mode (local or remote), the graph
home, the project slug for the current repo, your identity, and a health
probe. Because configuration comes from several layers (flags, environment,
`.spor.json`, user config), `status` is the authoritative answer to "which
graph am I on right now?" — more reliable than re-reading the config files
yourself. It also warns when a wired host is running a stale plugin version.

## spor-hook doctor

```sh
spor-hook doctor
```

Where `spor status` answers "what is configured", `doctor` answers "is the
automatic machinery healthy". It reports the resolved mode, whether the
server is reachable, whether your token is valid, the depth of the outbox and
dead-letter spool, how fresh the cached briefings are, and the most recent
hook and distiller errors. Because the hooks
[fail open](/use-spor/what-happens-automatically/), a quietly broken
setup still gives you working sessions — just with less context — so `doctor`
is how such a state becomes visible.

## The offline outbox

In remote mode, a `spor add` that cannot reach the team server — the server
is down, or ingestion takes longer than its budget — does not lose the
capture. It spools it to an outbox in your graph home and returns. Spooled
captures are replayed automatically: a later successful `spor add` drains the
outbox opportunistically, and a coding-agent session drains it at start.

If you work purely from the CLI and want to flush the spool by hand:

```sh
spor drain
```

Each spooled file is replayed to the server and removed once it ships.
Transient failures stay spooled for the next drain; permanent rejections
(for example, a capture made under a since-revoked token) move to a
`dead/` directory for inspection instead of retrying forever. `spor drain`
exits non-zero only when nothing could ship at all, which usually means the
server is still unreachable.

Local mode never spools — captures write straight to the graph on disk, so
there is nothing to drain.

:::tip
A capture that timed out on your side may still have landed: server-side
ingestion can complete after the client gave up. Before re-adding what looks
like a lost capture, check `spor changes` for it — otherwise you may file a
duplicate.
:::

## Slow first request after an idle period

In remote mode, Hosted Spor may need to wake an idle org before serving the
first request; this is usually quick, but occasionally longer. You do not
need to retry immediately, and requests after the first run at normal speed.

If requests keep failing rather than just starting slow, run
[`spor status`](#spor-status) or
[`spor-hook doctor`](#spor-hook-doctor).
`GET /v1/status` reports service health and basic operational metrics for
your organization's graph — see
[Data, privacy, and export](/hosted/data-privacy-and-export/).
