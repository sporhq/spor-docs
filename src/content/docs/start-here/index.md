---
title: Start here
description: Choose the right first path for local Spor, hosted Spor, or an assistant connector.
sidebar:
  order: 2
---

New to Spor? Start with [What is Spor?](/start-here/what-is-spor/) for the
plain-language introduction.

Spor runs in two modes, with the same CLI for both. In local mode, the graph
is a plain git repository of markdown files on your machine, `~/.spor` by
default. Use it to try Spor out or keep personal memory. In remote mode, your
team shares one live graph on a server. Writes are attributed to the person
or agent that made them, and captures are typed and linked by the server.

Every command resolves the mode from configuration. `spor status` always
shows which mode is active. You can move from local to remote later; the
graph format and the CLI do not change.

## Pick the path that matches how you are arriving

- [Try Spor locally](/start-here/try-spor-locally/) if you want to install
  the CLI, create a graph on your machine, and record one issue before a team
  or server is involved.
- [I was invited to hosted Spor](/start-here/invited-to-hosted-spor/) if your
  team already runs Spor and you have an invite token or sign-in path.
- [Connect an assistant](/start-here/connect-an-assistant/) if your team has
  hosted Spor, or a self-hosted Spor server, and you want claude.ai or Claude
  Code to use the same graph.

Integration builders should start with the
[REST API reference](/reference/api/).

## Supporting pages

- [Core ideas](/start-here/core-ideas/) explains the graph model.
- [What Spor is not](/start-here/what-spor-is-not/) explains the product's
  boundaries.
