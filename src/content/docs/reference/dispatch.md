---
title: Dispatch, capabilities, and profiles
description: Briefed background agents, machine capability maps, and profiles as satisfiability specs — with no silent substitution.
---

**Use this when** you run queue items as background agents with
`spor dispatch`, or need to control which toolset a dispatched session
launches with and which machines can take the work.

**You do not need this if** you work queue items yourself in an interactive
session; the everyday loop covers that without dispatch, starting with [The
decision queue](/use-spor/queue/). If you are implementing your own launcher
or harness adapter instead of using `spor dispatch`, the exact wire contract
it follows is on [Worker protocol](/reference/worker-protocol/).

**After reading this, you should be able to** choose the profile a dispatch
will use, read a capability refusal, and decide whether `requires:` belongs
on the work.

Dispatch launches a background agent with the right context already
attached:

```sh
spor dispatch issue-tidefall-double-charge    # brief + launch a background agent
spor dispatch --from-queue             # take the top ranked queue item
spor dispatch issue-tidefall-double-charge --print   # show what would launch
```

Dispatching a node compiles a briefing from its graph neighborhood and
injects it into the launched session, so the agent starts pre-briefed
instead of cold. Dispatch also refuses obvious duplicates: if the node is
already being worked locally, or already [claimed](/reference/graph-model/claims/) in
remote mode, the second dispatch is refused unless forced. Each dispatched
session runs under an [agent identity](/use-spor/identity/) its owner
created, so everything it writes reads "agent on behalf of person". A real
remote dispatch hard-fails rather than launching if no agent identity
resolves or minting its session token fails — naming `spor agent use
<agent-id>` as the fix — instead of silently attributing its writes to the
person; `--allow-person-token` (also `dispatch.allowPersonToken` /
`SPOR_ALLOW_PERSON_TOKEN`) is the explicit, loudly-warned escape hatch for
solo/local use. See [Worker protocol → Agent identity and
attribution](/reference/worker-protocol/#agent-identity-and-attribution)
for the full contract.

## Profiles: the how, factored out

A `profile-` node is a reusable runtime-plus-capability bundle — which
harness to launch, which model, which skills, plugins, and MCP servers the
session gets:

```markdown
---
id: profile-docs-writer
type: profile
title: Docs-writer profile
summary: Claude Code with the writing skill and the Spor MCP server.
harness: claude-code
model: opus
skills: [writing]
mcp: [spor]
status: active
date: 2026-06-01
---
```

Profiles are factored out of agents so a toolset is reusable across agents
and people, and they can be personal or org-published — a curated,
org-approved profile is where dispatch meets policy, since a policy can
require that risky work go only to agents running an approved toolset.

Which profile a dispatch uses follows an explicit-wins cascade: a
`--profile` flag on the dispatch beats a `profile:` attribute on the
`assigned` edge (the durable per-assignment override), which beats the
agent's default `uses-profile` edge.

## Choosing a harness

By default, `spor dispatch` launches a Claude Code agent under the same
supervisor every other harness runs under: headless print mode
(`claude -p --output-format stream-json`), with the prompt on stdin and the
run's session id and final report read off its event stream. That
supervision is what makes the [terminal-state
contract](/reference/worker-protocol/#terminal-states-the-outcome-contract)
enforceable — the runner can tell what the run actually did. Pass `--bg`
(or set `dispatch.claudeLaunchMode: native-background` in your user config)
to launch the native background session instead (`claude --bg`, the
attachable, interactive form reached with `claude attach`) at the cost of an
unenforced outcome — see below. `--bg` is `spor dispatch`'s alone: `spor
work` always launches supervised, since its runs must be followed, judged,
and gated.

To dispatch under a different coding-agent CLI — Codex, OpenCode, and GitHub
Copilot CLI are also supported — resolve a profile whose `harness:` field
names it:

```sh
spor dispatch issue-86 --profile profile-codex-sol
```

```markdown
---
id: profile-codex-sol
type: profile
title: Codex / gpt-5.6-sol
summary: Codex harness running gpt-5.6-sol — general-purpose dispatch profile.
status: active
harness: codex
model: gpt-5.6-sol
mcp: [spor]
---
```

Codex-specific flags (`--sandbox`, `--approval-policy`) and Claude-specific
ones (`--permission-mode`, `--agent`) are mutually exclusive — passing the
wrong one for the resolved harness is a hard error, so a dispatch can't
launch half-configured for the wrong CLI. The one exception:
`--permission-mode bypassPermissions` against a Codex profile has a real
Codex equivalent ("run fully unattended"), so instead of erroring it
translates to `--sandbox danger-full-access --approval-policy never` (an
explicit `--sandbox`/`--approval-policy` you also pass wins over that
default) and prints a loud warning naming the translation — so an
orchestrator or script that passes the same bypass flag to every dispatch
regardless of harness keeps working. Every other permission-mode value still
hard-errors against Codex.

The harnesses do not all confine a run the same way. Codex dispatch defaults
to `--sandbox workspace-write`, so its filesystem reach is bounded. OpenCode
(`--auto`) and GitHub Copilot CLI (`--allow-all --no-ask-user`) have no
equivalent — a dispatch under either runs with unrestricted tool access,
because an unattended run has no human to answer a permission prompt.
Dispatch those into a worktree or a checkout you are willing to have an
agent change.

**Naming a launcher explicitly.** A dispatched run does not inherit your
interactive shell, so a CLI installed under a prefix that only an
interactive shell sees (a common Homebrew setup) resolves when you check it
by hand and resolves to nothing when Spor launches it. Point Spor at the
binary directly rather than relying on `PATH`, in `~/.spor/config.json` —
machine-specific, like `dispatch.repos`, so it never belongs in a
committable `.spor.json`:

```json
{ "dispatch": { "bin": { "opencode": "/home/linuxbrew/.linuxbrew/bin/opencode" } } }
```

`SPOR_CLAUDE_CMD` / `SPOR_CODEX_CMD` / `SPOR_OPENCODE_CMD` /
`SPOR_COPILOT_CMD` override the same thing per harness and win over the
config file. An explicit launcher is used verbatim and is never quietly
swapped for something on `PATH`; with none set, the bare name resolves on
`PATH` as before.

Only a `--bg` Claude Code dispatch launches differently from the rest.
Detaching into Claude Code's own background-agent daemon means the launcher
exits immediately, and `spor dispatch` can only reconcile what happened to
it afterwards from the harness's own session transcript. Every supervised
harness — Claude Code by default, Codex, OpenCode, GitHub Copilot CLI —
instead runs under a small supervisor Spor itself owns: it launches the
CLI's headless mode in the background, streams its progress into a private
log, and captures the run's final message to a report file. At launch it
prints where everything lives:

```text
run:     3f9a2c1e-... (Codex supervisor running)
log:     ~/.spor/journal/dispatch/3f9a2c1e-....log
report:  ~/.spor/journal/dispatch/3f9a2c1e-....report.md
session: 019f7a51-...
```

`log` is the full JSONL progress stream; `report` is the run's final message —
the thing to read for "what did it conclude". Both paths, plus the run's
outcome, are recorded durably and can be looked up later with
[`spor runs`](/reference/cli/dispatch/#runs):

```sh
spor runs --node issue-86            # human-readable: state, why, log path
spor runs --node issue-86 --json     # add .runs[0].report_path for the final message
```

## Capabilities: what this machine can actually run

Each machine keeps a local, never-committed capability map — which harnesses
are installed, which MCP servers are reachable, which skills and plugins are
present (`spor capabilities list` shows it; a probe seeds it). In a fleet,
each agent can publish its capabilities to the server and heartbeat its
liveness, so hosts can be matched remotely.

**The profile's runtime fields are the satisfiability spec** — there is no
separate requirements block. A machine satisfies a profile when it has the
profile's harness, can reach its MCP servers, and carries its skills and
plugins, and the profile is not on the machine's deny list.

## No silent substitution

If no machine satisfies the resolved profile, dispatch fails soft and loud:
the assignment stays intact, the refusal names the missing capabilities, and
Spor **never substitutes a different profile**. A dispatch that asked for
the reviewer toolset must not quietly run under whatever was available —
predictability of what an agent ran with is worth more than the convenience
of running anyway. When a fleet is available, the refusal instead lists the
machines that *do* satisfy the profile, so the work re-routes rather than
degrades.

## Auto-route: closing the loop without a human

The refusal above still leaves a person to read the fleet-host list and
re-route the item by hand. `--auto-route` (the `dispatch.autoRoute` config
key, `SPOR_AUTO_ROUTE`; default **off**) closes that loop: on the same
unsatisfiable-here refusal, a **node** dispatch asks the fleet scheduler for
the caller's own hosts and hands the item to the freshest one that satisfies
the profile, by writing `assigned -> <host agent>` with the **same** profile
pinned on the edge — so that box's own `spor work` picks the item up on its
next poll, with nobody re-routing it by hand.

This is a re-route, not a remote launch: routing is explicit assignment (an
`assigned` edge on the graph), so there is no cross-machine exec channel and
auto-route does not build one. The invariants from [No silent
substitution](#no-silent-substitution) still hold:

- the profile id on the edge is the one that was refused here — auto-route
  never substitutes a different profile;
- only the caller's **own** agents are ever considered (`owner=me`), so an
  admin's dispatch never hands work to a colleague's machine;
- the refusing box is never its own re-route target;
- when no host satisfies the profile, the refusal still **escalates to the
  owner**, exactly as it would without `--auto-route` — it never downgrades
  to a different profile, and never runs anyway.

The dispatching box still refuses (exit 1) and its worker cools the item off
as usual, because nothing ran *here*. `dispatch.autoRouteMaxAge`
(`SPOR_AUTO_ROUTE_MAX_AGE`; default `24h`, `0` disables the bound) caps how
stale a target's last contact may be — generous, because a box idling in
`spor work` goes quiet between heartbeats without going away.
`--no-auto-route` opts a single run out of a standing `dispatch.autoRoute:
true` default. With auto-route off, not one extra network call runs and the
refusal is byte-identical to before. A free-text dispatch (no node to
assign) has nothing to re-route, so it always falls back to the human-tier
report above.

## The `requires:` risk register

Distinct from machine satisfiability, a work node can declare what the work
may *touch*:

```yaml
requires: [shell, prod-creds]
```

The vocabulary is an extensible registry enum seeded with `shell`,
`prod-creds`, `browser`, `network`, `human`, `filesystem-write`, and
`paid-api`; a team grows it by editing a schema node. Satisfiability asks
"can this box launch the profile"; `requires:` asks "may this work touch
these things", validated against the assigned profile's granted classes and
gated by org policy. `human` is unsatisfiable by any agent — that work goes
to a person.

## Agent-readiness before launch

Dispatching a node also checks its derived
[agent-readiness](/reference/graph-model/node-types/#agent-readiness) before any
claim, lease, or launch:

- **`requires: human`** — the risk register's own declaration that no agent
  can do this work, regardless of capability — refuses outright, naming the
  gap, with **no `--force` override** (overriding it would be exactly the
  silent substitution the profile-satisfiability rule above also forbids).
  The assignment is left completely unchanged; a human must do the work, or
  edit the node's `requires:` list, then dispatch again.
- A **broader `readiness: human`** classification — assigned to a person, or
  a held task, or (in local mode only — see below) an open question on the
  item or in its 1-hop neighborhood — is not a capability gap, so it only
  **warns**: dispatch prints the reason and proceeds.
- A clean, agent-ready, or untriaged item produces no guard output at all.

`--print`/dry-run shows the same distinction ahead of a real launch. Local
mode runs the exact ranking derivation `spor next` uses, front-activity
signal included. Remote mode has no client-side graph to walk, so it
approximates from the node's own frontmatter and its `assigned` edges,
through the same classification logic — but it deliberately skips the
1-hop-neighborhood open-question check (a second network fetch for a
warn-only signal), so a node whose only human trigger is an open question on
a *neighboring* node warns locally but not over a remote dispatch.

## Routines

A `routine-` node, owned by a person, holds declarative trigger-to-action
rules over graph events — for example, "when a node I steward gets a
`changes-requested-by` edge, dispatch my fix-up agent". Two invariants hold:
only the owner's agents are ever dispatched, and personal routines
accelerate but never bypass org policy — an agent acting for its owner
counts as the owner for every gate, so automation cannot launder approvals.
Routines are declarative today; the engine that fires them is still rolling
out, so treat them as the shape of the automation layer rather than a
finished surface.
