---
title: spor-hook
description: The hook-dispatcher binary agent hosts call automatically, and spor-hook doctor, the one verb meant to be run by hand.
sidebar:
  order: 10
---

**Use this when** you want to know what a wired host's hooks config is
actually invoking, or what `spor-hook doctor` checks before you run it.

**You do not need this if** you just want to run the diagnostic; the
[Diagnostics](/reference/diagnostics/) page walks through reading its output.

**After reading this, you should be able to** tell which `spor-hook` events
are wired automatically versus the one meant to be typed by hand, and read
every field `spor-hook doctor` reports.

`spor-hook` is a second, much smaller binary installed alongside `spor` — the
hook dispatcher that [`spor install`](/reference/cli/setup-and-identity/#install)
wires into an agent host's own hook configuration. Hosts invoke it with a host
payload on stdin and read a context envelope back on stdout; you don't run
most of its events yourself. `spor-hook <event>` with no recognized event
name prints an error to stderr naming the unknown event; `spor version`
reports which package version's behavior this page describes.

## Hook events

These fire automatically once a host is wired (`spor install`) and the repo is
enabled (`spor enable`). Each corresponds to one of the four hooks described in
[What happens automatically](/use-spor/what-happens-automatically/); you would
only invoke one directly to reproduce a host's exact call while debugging.

| Event | Fires | Flags |
| --- | --- | --- |
| `session-start` | a session starts or resumes | `--host <claude-code\|codex\|gemini\|cursor\|copilot\|opencode>` |
| `prompt-context` | each prompt you submit | `--host <host>` |
| `post-tool` | after a file edit or shell command | `--host <host>` |
| `distill` | session end | `--host <host>`, `--debounce <seconds>` |

`--host` names the calling host, not the argument `spor install` takes for the
same host — this is `claude-code` for Claude Code where `spor install` takes
`claude`, and matches what the shipped hooks manifest for each host actually
passes. All four events read a JSON payload from stdin and, on success, write
a `{hookSpecificOutput: {hookEventName, additionalContext}}` envelope to
stdout (Cursor gets a flattened `{additional_context}` instead — see its host
mapping below). `--debounce` on `distill` spools the payload and hands off to
a per-session watcher that fires once the session goes quiet, instead of
distilling on every call.

Every event fails open: a crash or a missing/invalid config never raises an
error — it exits 0, so a hook problem never costs you the session. A crashed
or misconfigured event exits with no output; the one exception is
`session-start` on a repo that's opted out purely by the silent default,
which can emit a one-time discovery hint instead of staying silent, if this
machine has prior Spor history for it. See [Everything fails
open](/use-spor/what-happens-automatically/#everything-fails-open).

### Host payload mapping

Cursor and Copilot name their payload fields differently from the
Claude-shaped JSON the engines expect; `spor-hook` normalizes both before
dispatching:

- **cursor** — `workspace_roots[0]` becomes `cwd`, `conversation_id` becomes
  `session_id`, and an `afterFileEdit` event's bare `file_path` is folded into
  a synthesized `tool_input`.
- **copilot** — `sessionId`, `toolName`, `toolArgs`, and `transcriptPath`
  become the canonical `session_id`, `tool_name`, `tool_input`, and
  `transcript_path`.
- Any host's `tool_input.path` (Codex's `apply_patch`, Copilot's `toolArgs`)
  folds into `tool_input.file_path` if that field isn't already set.

## agents-md

```
spor-hook agents-md [--cwd <dir>]
```

Takes no stdin when run standalone (a `--cwd` flag or a TTY skips the stdin
read). Writes or refreshes the managed Spor block in `AGENTS.md` at the repo
root — the session-start floor for hosts that don't support hooks, so those
sessions still pick up the capture-discipline directive and, where
configured, the standing project briefing. This is the same writer behind
the [`spor agents-md`](/reference/cli/repo-scoping/#agents-md) CLI verb; run
that one directly if you want to refresh `AGENTS.md` by hand.

## doctor

```
spor-hook doctor [--cwd <dir>]
```

The one `spor-hook` event meant to be run directly. An operator-run
diagnostic, not a host hook: it takes no stdin, prints a human-readable
report, and runs even when the plugin is disabled for the repo — a disabled
plugin is exactly the state you'd want it to report. Where [`spor
status`](/reference/cli/setup-and-identity/#status) answers "what is
configured", `doctor` answers "is the automatic machinery healthy":

- **mode / graph home** — the resolved mode and, if the repo is disabled
  here, a reminder to run `spor enable`.
- **server / reachable / token** (remote mode) — whether the configured
  server responds and whether the bearer token is valid, rejected, or
  missing.
- **graph** (local mode) — the node count under the local graph home.
- **outbox / dead-letter** (remote mode) — how many captures are spooled
  awaiting the next drain, and how many permanently failed into
  `outbox/dead/`, each with the oldest entry's age.
- **cache** (remote mode) — how long ago each cached briefing was fetched,
  the offline-fallback freshness signal.
- **distill / nudge** — the capture pipelines' success rate over the
  trailing window: idle (no calls), a failure count and last error, or a
  percentage with the last success's age.
- **remote.log / distill.log** — the most recent error-ish lines from each
  journal, so a quietly failing hook leaves a trail even though it fails
  open.

```sh
spor-hook doctor
```

The fuller walkthrough of reading this output — alongside `spor status`, the
offline outbox, and the slow-first-request case — is on the
[Diagnostics](/reference/diagnostics/) page.
