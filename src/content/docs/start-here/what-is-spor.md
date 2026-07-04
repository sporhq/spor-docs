---
title: What is Spor?
description: What Spor keeps for a team, what it does with that record, and the few terms the rest of the docs use.
sidebar:
  order: 1
---

Spor keeps the decisions, tasks, questions, rules, and notes behind your work in one shared record. People and AI assistants can use that record to pick up context, avoid repeating old mistakes, and see why work moved in a certain direction.

That record is meant for durable outcomes, not every message or passing thought. A decision can include the approach the team chose, the alternatives it rejected, and the reason the answer should still guide related work.

For example, a small SaaS team at tidefall decides how many times to retry a failed card charge before asking the customer to update billing details. Months later, someone new starts changing the billing retry flow. Spor can show the earlier decision, the rejected approach, and the open follow-up work before that person, or their AI assistant, starts from memory or repeats the same debate.

## Day to day

When a coding session starts in a repository where Spor is enabled, Spor gathers the relevant history first: decisions that still apply, rejected approaches, open tasks and blockers, and team conventions. The docs call this assembled context a briefing.

Spor also keeps a ranked list of open work, ordered by signals such as what each item blocks and how old it is. The docs call this list the queue. When work produces a new outcome, Spor records it back into the shared record. If a newer decision replaces an older one, the record shows what replaced it and why, and the older answer stops being served as current.

The same tool works in local and remote mode. In local mode, the record is plain markdown files in a git repository on your machine, with no server and no database. In remote mode, a team shares one live record on a server, and every write is attributed to the person or AI agent that made it. Spor works from the command line and inside AI coding assistants as a plugin or connector.

## Terms used later

Spor stores each durable piece of work as an item. In the reference docs, these are called nodes. Links between items are called edges.

The reference section documents the full model for nodes, edges, and the shared record.

## Where next

- [Try Spor locally](/start-here/try-spor-locally/)
- [I was invited to hosted Spor](/start-here/invited-to-hosted-spor/)
- [Connect an assistant](/start-here/connect-an-assistant/)
- [Read the core ideas](/start-here/core-ideas/)
- [See what Spor is not](/start-here/what-spor-is-not/)
