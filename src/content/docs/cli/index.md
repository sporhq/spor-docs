---
title: CLI reference
description: Every spor verb, with flags, aliases, and the mode it runs in.
sidebar:
  order: 1
---

The `spor` command line is the shell surface for the graph. One binary
serves both modes: **local**, where the graph is a git repository of
markdown files on your machine, and **remote**, where your team shares one
graph on the Spor server. Each verb resolves local-versus-remote per call,
so scripts and habits carry over when a personal graph grows into a team
one. This reference documents the binary's own help as of version 0.18.5;
`spor help <command>` is always the word on the version you have installed.

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
[Configuration](/cli/configuration/) page.

## Command groups

| Page | Verbs |
| --- | --- |
| [Getting started verbs](/cli/getting-started/) | init, install, upgrade, status, join, auth, login, migrate, whoami, person, token |
| [Team administration](/cli/team-admin/) | invite, admin |
| [Reading the graph](/cli/reading-the-graph/) | next, get, query, blame, history, changes, analytics, schema, lens, share, export |
| [Writing to the graph](/cli/writing-to-the-graph/) | add, ask, drain, put-node, edge, set-status, priority, correct, claim, renew, extend, release, run |
| [Repo scoping](/cli/repo-scoping/) | enable, disable, link, agents-md, compile, brief, validate |
| [Dispatch](/cli/dispatch/) | agent, dispatch, repos, capabilities |
| [Utilities](/cli/utilities/) | cost, version, help |

## All verbs, A to Z

| Verb | Mode | Alias | What it does |
| --- | --- | --- | --- |
| [add](/cli/writing-to-the-graph/#add) | dual | `capture` | capture a node from prose |
| [admin](/cli/team-admin/#admin) | remote | | gardener sweep and team token admin |
| [agent](/cli/dispatch/#agent) | dual | | person-owned automation identities and their standing tokens |
| [agents-md](/cli/repo-scoping/#agents-md) | local | `agents` | write or refresh the committed AGENTS.md graph-upkeep directive |
| [analytics](/cli/reading-the-graph/#analytics) | dual | | created-vs-completed work metrics |
| [ask](/cli/writing-to-the-graph/#ask) | dual | `question` | file a question the graph can't answer |
| [auth](/cli/getting-started/#auth) | remote | | sign in and manage org-scoped credentials |
| [blame](/cli/reading-the-graph/#blame) | dual | `commits` | which nodes reference a commit |
| [brief](/cli/repo-scoping/#brief) | dual | | compile a briefing for a node |
| [capabilities](/cli/dispatch/#capabilities) | dual | `caps`, `profiles` | this machine's dispatch capability map |
| [changes](/cli/reading-the-graph/#changes) | dual | | recent graph activity feed |
| [claim](/cli/writing-to-the-graph/#claim) | remote | | take the heartbeat-renewed lease on a task |
| [compile](/cli/repo-scoping/#compile) | dual | | full neighborhood or prompt-time digest |
| [correct](/cli/writing-to-the-graph/#correct) | dual | `propose-correction` | record a standing briefing correction |
| [cost](/cli/utilities/#cost) | local | | LLM spend summary |
| [disable](/cli/repo-scoping/#disable) | local | | turn Spor off for this repo |
| [dispatch](/cli/dispatch/#dispatch) | dual | `bg` | compile a briefing and launch a background agent |
| [drain](/cli/writing-to-the-graph/#drain) | remote | `sync` | flush spooled captures to the team server |
| [edge](/cli/writing-to-the-graph/#edge) | dual | `add-edge` | add a typed edge from a node |
| [enable](/cli/repo-scoping/#enable) | local | | opt this repo in |
| [export](/cli/reading-the-graph/#export) | dual | | the nodes tarball, history bundle, or restore backup |
| [extend](/cli/writing-to-the-graph/#extend) | remote | | extend your live claim by a duration |
| [get](/cli/reading-the-graph/#get) | dual | | one node by id |
| [help](/cli/utilities/#help) | local | | the verb list, or a command's detailed help |
| [history](/cli/reading-the-graph/#history) | dual | | a node's commit lineage |
| [init](/cli/getting-started/#init) | local | | create the local graph home |
| [install](/cli/getting-started/#install) | local | `setup` | wire spor into an agent |
| [invite](/cli/team-admin/#invite) | remote | | mint a teammate token (admin) |
| [join](/cli/getting-started/#join) | remote | | add an org-scoped credential from a pasted token |
| [lens](/cli/reading-the-graph/#lens) | remote | `render-lens` | render a saved view |
| [link](/cli/repo-scoping/#link) | local | | set this repo's canonical project slug |
| [login](/cli/getting-started/#login) | remote | | interactive sign-in (alias of `auth login`) |
| [migrate](/cli/getting-started/#migrate) | local | `push` | push the local graph to a git remote you own |
| [next](/cli/reading-the-graph/#next) | dual | `queue` | the ranked decision queue |
| [person](/cli/getting-started/#person) | local | | create or list local person nodes |
| [priority](/cli/writing-to-the-graph/#priority) | dual | `set-priority` | set a queue item's human-triage priority |
| [put-node](/cli/writing-to-the-graph/#put-node) | dual | | write a full node markdown file |
| [query](/cli/reading-the-graph/#query) | dual | | filterable node and edge enumeration |
| [release](/cli/writing-to-the-graph/#release) | remote | | hand a task back to the pool |
| [renew](/cli/writing-to-the-graph/#renew) | remote | | heartbeat your live claim |
| [repos](/cli/dispatch/#repos) | dual | | the dispatch slug map and repo-identity tags |
| [run](/cli/writing-to-the-graph/#run) | remote | | start or inspect a workflow run |
| [schema](/cli/reading-the-graph/#schema) | dual | | introspect the live schema registry |
| [set-status](/cli/writing-to-the-graph/#set-status) | dual | `status-set` | set a node's status, claiming on active |
| [share](/cli/reading-the-graph/#share) | remote | | mint a shareable read-only view link |
| [status](/cli/getting-started/#status) | dual | | resolved mode, graph, project, identity, health |
| [token](/cli/getting-started/#token) | remote | | self-serve personal access tokens |
| [upgrade](/cli/getting-started/#upgrade) | local | `update` | refresh wired spor to the installed version |
| [validate](/cli/repo-scoping/#validate) | local | | lint the local graph |
| [version](/cli/utilities/#version) | local | | print the package version |
| [whoami](/cli/getting-started/#whoami) | remote | | who the team graph thinks you are |
