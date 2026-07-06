---
title: Ask and answer questions
description: File a question the graph cannot answer, how routing finds the person who knows, and how an answers edge closes the loop.
sidebar:
  order: 3
---

When the graph cannot answer something a teammate would know, file a question
instead of letting it disappear into the session. A filed question becomes a
`question-` node and joins [the decision queue](/use-spor/queue/) until it is
answered.

## File the question

`spor ask "Did the dunning email copy get updated for the three-attempt retry window?"` records an open question. The command is also
available as `spor question`, and it works in both local mode and remote mode:
in remote mode the server routes the question and attributes it to your token;
in local mode it writes an open, queueable question node so it still appears
in `spor next`.

Use `--mention <id>` to name a node the question is about:

```sh
spor ask "Did the dunning email copy get updated for the three-attempt retry window?" --mention dec-tidefall-billing-retries
```

`--mention` is repeatable. Routing weighs explicit mentions first, and in
local mode each mention becomes a `mentions` edge. If the question has no
mentions and no useful neighborhood, pass `--project billing` so the question
lands in the right project.

In an agent session, use `/spor:ask`. From an MCP host such as claude.ai, use
the [`ask_question` tool](/reference/mcp/tools/#ask_question), which takes
`{text, title?, mentions?, project?}`. The full CLI entry is in
[Writing to the graph](/reference/cli/writing-to-the-graph/#ask).

## How routing finds the steward

In remote mode, question routing is deterministic. The server walks
`stewards` edges from the question's relevance neighborhood, with explicit
mentions weighed first, to find the closest steward. It then writes a
`routed-to` edge to that person.

That person's queue shows the question; everyone else's queue does not. If no
steward matches, the question surfaces to everyone. It is still answerable,
just not directed.

Routing depends on the graph's stewardship edges. A person node carrying a
`stewards` edge to a spec or area is what makes questions about that area land
on that person's queue. See
[Identity and attribution](/use-spor/identity/) for person nodes and
`stewards` edges.

Local mode does not route questions. The question sits in the queue like any
other open queueable node.

## Answer with lineage

The answer loop is lineage, not messaging. Whoever knows writes a node, then
adds an `answers` edge from that answer node back to the question. The answer
can be a decision, an artifact, or a short answer artifact.

Both nodes must already exist before adding the edge:

```sh
spor edge art-tidefall-dunning-copy answers question-tidefall-dunning-copy
spor set-status question-tidefall-dunning-copy answered
```

`spor edge` is idempotent when the same edge already exists. The full command
entries are in the [`edge`](/reference/cli/writing-to-the-graph/#edge) and
[`set-status`](/reference/cli/writing-to-the-graph/#set-status) references.

The edge is the truth the queue reads. A question retired by a live inbound
`answers` edge is excluded from the queue even if its status field has not yet
caught up.

The asker's next [briefing](/use-spor/briefings/) pulls the answer through the
question's neighborhood. Nobody has to remember to reply in the right channel.

For example, `person-ines` stewards the billing area for tidefall. A question
about dunning email copy and `dec-tidefall-billing-retries` lands on her
queue. She records the answer:

```sh
spor add "The dunning email copy shipped with the three-attempt retry window. After the third failed charge, the email asks the customer to update billing details."
```

In remote mode, the server types and links that capture. After the answer node
exists, Ines adds its `answers` edge back to the question and marks the
question `answered`.

Questions usually start where capture leaves off: use
[capture and ingestion](/use-spor/capture/) for what you learned, and use a
question when the missing fact belongs with a teammate.
