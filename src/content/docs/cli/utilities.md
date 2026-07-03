---
title: Utilities
description: LLM spend reporting, the version banner, and per-command help.
sidebar:
  order: 8
---

### cost

```
spor cost [--since <YYYY-MM-DD>] [--until <YYYY-MM-DD>] [--project <slug>] [--json]
```

**Mode:** local

Summarize recorded LLM spend from the graph home's `journal/llm-calls` log.
`--since`/`--until` bound the date range; `--project` scopes to one project.

```bash
spor cost --since 2026-06-01
```

### version

```
spor version
```

**Mode:** local

Print the installed package version.

```bash
spor version
```

### help

```
spor help [<command>]
```

**Mode:** local

Print the full verb list, or one command's detailed help — synopsis,
aliases, flags, and examples. `spor <command> --help` is equivalent.

```bash
spor help dispatch
```
