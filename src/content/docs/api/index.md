---
title: REST API
description: The versioned HTTP contract — endpoints, authentication, and errors.
sidebar:
  order: 1
---

:::note
This section is under construction. It will document every endpoint of the
versioned HTTP API — reads, writes, leases, lenses, tokens, agents, and
workflow runs — along with authentication (personal access tokens, OAuth 2.1,
device grant) and the error contract.
:::

Everything the CLI and connectors do goes through one plain HTTPS + JSON
API, versioned under `/v1/` and authenticated with a bearer token on every
route.
