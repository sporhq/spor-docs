---
title: CLI reference
description: Every spor verb, with flags, aliases, and the mode it runs in.
sidebar:
  order: 1
---

**Use this when** you are looking up the exact behavior of a `spor` verb: its
flags, aliases, and which mode it runs in.

**You do not need this if** you came to complete a task rather than look up a
verb; start with [Common CLI tasks](/reference/cli/common-tasks/), or use
[Start here](/start-here/) for first-time setup.

**After reading this, you should be able to** find a verb's entry, read its
mode badge, and check the installed version's own help with
`spor help <command>`.

The `spor` command line is the shell surface for the graph. One binary
serves both modes: **local**, where the graph is a git repository of
markdown files on your machine, and **remote**, where your team shares one
graph on the Spor server. Each verb resolves local-versus-remote per call,
so scripts and habits carry over when a personal graph grows into a team
one. This reference documents the binary's own help; `spor help <command>`
is always the word on the version you have installed.

If you came to do something specific rather than look up a verb, start with
[Common CLI tasks](/reference/cli/common-tasks/): short recipes that link into
the verb entries here.

Installing the package also gives you a second, much smaller binary:
`spor-hook`, the dispatcher wired hosts call automatically, plus the
`doctor` diagnostic meant to be run by hand. It has its own entry: [the
spor-hook reference](/reference/cli/spor-hook/).

## Mode badges

Every verb on the following pages carries one of three badges:

- **local** — runs entirely against files on your machine; no server is
  involved. Includes machine and repo configuration verbs.
- **remote** — needs a team server. In local mode these verbs degrade with
  a one-line explanation rather than an error.
- **dual** — works in both modes, resolving per call: local mode reads and
  writes the graph home on disk, remote mode calls the server, and output
  is designed to match across modes.

Mode is set by configuration: `SPOR_SERVER` in the environment (or the
equivalent config key) resolves to remote, unset means local against
`$SPOR_HOME`. `spor status` reports what resolved and why. The full cascade,
the `.spor`/`.spor.json` repo markers, and the credential store are on the
[Configuration](/reference/configuration/) page.

## Command groups

| Page | Verbs |
| --- | --- |
| [Setup and identity](/reference/cli/setup-and-identity/) | init, install, upgrade, status, join, auth, login, migrate, whoami, person, token |
| [Team administration](/reference/cli/team-admin/) | invite, admin |
| [Reading the graph](/reference/cli/reading-the-graph/) | next, get, query, blame, history, changes, analytics, schema, lens, share, export |
| [Writing to the graph](/reference/cli/writing-to-the-graph/) | add, ask, drain, put-node, edge, set-status, priority, ready, correct, claim, renew, extend, release, run |
| [Repo scoping](/reference/cli/repo-scoping/) | enable, disable, link, agents-md, compile, brief, validate |
| [Dispatch](/reference/cli/dispatch/) | agent, dispatch, work, runs, repos, capabilities |
| [Utilities](/reference/cli/utilities/) | cost, version, help |

## All verbs, A to Z

| Verb | Mode | Alias | What it does |
| --- | --- | --- | --- |
| [add](/reference/cli/writing-to-the-graph/#add) | dual | `capture` | capture a node from prose |
| [admin](/reference/cli/team-admin/#admin) | remote | | gardener sweep and team token admin |
| [agent](/reference/cli/dispatch/#agent) | dual | | person-owned automation identities and their standing tokens |
| [agents-md](/reference/cli/repo-scoping/#agents-md) | local | `agents` | write or refresh the committed AGENTS.md graph-upkeep directive |
| [analytics](/reference/cli/reading-the-graph/#analytics) | dual | | created-vs-completed work metrics |
| [ask](/reference/cli/writing-to-the-graph/#ask) | dual | `question` | file a question the graph can't answer |
| [auth](/reference/cli/setup-and-identity/#auth) | remote | | sign in and manage org-scoped credentials |
| [blame](/reference/cli/reading-the-graph/#blame) | dual | `commits` | which nodes reference a commit |
| [brief](/reference/cli/repo-scoping/#brief) | dual | | compile a briefing for a node |
| [capabilities](/reference/cli/dispatch/#capabilities) | dual | `caps`, `profiles` | this machine's dispatch capability map |
| [changes](/reference/cli/reading-the-graph/#changes) | dual | | recent graph activity feed |
| [claim](/reference/cli/writing-to-the-graph/#claim) | remote | | take the heartbeat-renewed lease on a task |
| [compile](/reference/cli/repo-scoping/#compile) | dual | | full neighborhood or prompt-time digest |
| [correct](/reference/cli/writing-to-the-graph/#correct) | dual | `propose-correction` | record a standing briefing correction |
| [cost](/reference/cli/utilities/#cost) | local | | LLM spend summary |
| [disable](/reference/cli/repo-scoping/#disable) | local | | turn Spor off for this repo |
| [dispatch](/reference/cli/dispatch/#dispatch) | dual | `bg` | compile a briefing and launch a background agent |
| [drain](/reference/cli/writing-to-the-graph/#drain) | remote | `sync` | flush spooled captures to the team server |
| [edge](/reference/cli/writing-to-the-graph/#edge) | dual | `add-edge` | add a typed edge from a node |
| [enable](/reference/cli/repo-scoping/#enable) | local | | opt this repo in |
| [export](/reference/cli/reading-the-graph/#export) | dual | | the nodes tarball, history bundle, or restore backup |
| [extend](/reference/cli/writing-to-the-graph/#extend) | remote | | extend your live claim by a duration |
| [get](/reference/cli/reading-the-graph/#get) | dual | | one node by id |
| [help](/reference/cli/utilities/#help) | local | | the verb list, or a command's detailed help |
| [history](/reference/cli/reading-the-graph/#history) | dual | | a node's commit lineage |
| [init](/reference/cli/setup-and-identity/#init) | local | | create the local graph home |
| [install](/reference/cli/setup-and-identity/#install) | local | `setup` | wire spor into an agent |
| [invite](/reference/cli/team-admin/#invite) | remote | | mint a teammate token (admin) |
| [join](/reference/cli/setup-and-identity/#join) | remote | | add an org-scoped credential from a pasted token |
| [lens](/reference/cli/reading-the-graph/#lens) | remote | `render-lens` | render a saved view |
| [link](/reference/cli/repo-scoping/#link) | local | | set this repo's canonical repo slug |
| [login](/reference/cli/setup-and-identity/#login) | remote | | interactive sign-in (alias of `auth login`) |
| [migrate](/reference/cli/setup-and-identity/#migrate) | local | `push` | push the local graph to a git remote you own |
| [next](/reference/cli/reading-the-graph/#next) | dual | `queue` | the ranked decision queue |
| [person](/reference/cli/setup-and-identity/#person) | local | | create or list local person nodes |
| [priority](/reference/cli/writing-to-the-graph/#priority) | dual | `set-priority` | set a queue item's human-triage priority |
| [put-node](/reference/cli/writing-to-the-graph/#put-node) | dual | | write a full node markdown file |
| [query](/reference/cli/reading-the-graph/#query) | dual | | filterable node and edge enumeration |
| [ready](/reference/cli/writing-to-the-graph/#ready) | dual | | stamp or clear a node's agent-readiness override |
| [release](/reference/cli/writing-to-the-graph/#release) | remote | | hand a task back to the pool |
| [renew](/reference/cli/writing-to-the-graph/#renew) | remote | | heartbeat your live claim |
| [repos](/reference/cli/dispatch/#repos) | dual | | the dispatch slug map and repo-identity tags |
| [run](/reference/cli/writing-to-the-graph/#run) | remote | | start or inspect a workflow run |
| [runs](/reference/cli/dispatch/#runs) | local | | what happened to the runs this machine dispatched |
| [schema](/reference/cli/reading-the-graph/#schema) | dual | | introspect the live schema registry |
| [set-status](/reference/cli/writing-to-the-graph/#set-status) | dual | `status-set` | set a node's status, claiming on active |
| [share](/reference/cli/reading-the-graph/#share) | remote | | mint a shareable read-only view link |
| [status](/reference/cli/setup-and-identity/#status) | dual | | resolved mode, graph, project, identity, health |
| [token](/reference/cli/setup-and-identity/#token) | remote | | self-serve personal access tokens |
| [upgrade](/reference/cli/setup-and-identity/#upgrade) | local | `update` | refresh wired spor to the installed version |
| [validate](/reference/cli/repo-scoping/#validate) | local | | lint the local graph |
| [version](/reference/cli/utilities/#version) | local | | print the package version |
| [whoami](/reference/cli/setup-and-identity/#whoami) | remote | | who the team graph thinks you are |
| [work](/reference/cli/dispatch/#work) | dual | | loop dispatch over the queue continuously, gated and enforced |
