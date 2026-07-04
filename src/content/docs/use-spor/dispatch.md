---
title: Dispatch, capabilities, and profiles
description: Briefed background agents, machine capability maps, and profiles as satisfiability specs — with no silent substitution.
sidebar:
  order: 6
---

Dispatch launches a background agent with the right context already
attached:

```bash
spor dispatch issue-webhook-retries    # brief + launch a background agent
spor dispatch --from-queue             # take the top ranked queue item
spor dispatch issue-webhook-retries --print   # show what would launch
```

Dispatching a node compiles a briefing from its graph neighborhood and
injects it into the launched session, so the agent starts pre-briefed
instead of cold. Dispatch also refuses obvious duplicates: if the node is
already being worked locally, or already [claimed](/reference/graph-model/claims/) in
team mode, the second dispatch is refused unless forced. Each dispatched
session runs under an [agent identity](/use-spor/identity/) its owner
created, so everything it writes reads "agent on behalf of person".

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
