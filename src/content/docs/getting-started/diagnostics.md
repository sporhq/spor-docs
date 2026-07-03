---
title: Diagnostics
description: spor status, spor-hook doctor, and the offline outbox — how to see what Spor resolved and recover spooled captures.
sidebar:
  order: 7
---

When something is unclear — no briefing appeared, a capture seems lost, you
are not sure which graph you are writing to — two commands answer almost
everything.

## spor status

```bash
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

```bash
spor-hook doctor
```

Where `spor status` answers "what is configured", `doctor` answers "is the
automatic machinery healthy". It reports the resolved mode, whether the
server is reachable, whether your token is valid, the depth of the outbox and
dead-letter spool, how fresh the cached briefings are, and the most recent
hook and distiller errors. Because the hooks
[fail open](/getting-started/what-happens-automatically/), a quietly broken
setup still gives you working sessions — just with less context — so `doctor`
is how such a state becomes visible.

## The offline outbox

In remote mode, a `spor add` that cannot reach the team server — the server
is down, or ingestion takes longer than its budget — does not lose the
capture. It spools it to an outbox in your graph home and returns. Spooled
captures are replayed automatically: a later successful `spor add` drains the
outbox opportunistically, and a coding-agent session drains it at start.

If you work purely from the CLI and want to flush the spool by hand:

```bash
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
