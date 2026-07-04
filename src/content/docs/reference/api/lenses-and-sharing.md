---
title: Lenses and sharing
description: Render saved views and mint read-only, expiring share tickets.
sidebar:
  order: 6
---

A lens is a saved view over the graph — a `type: lens` node whose render
produces a view tree. The render route serves it to browsers and teammates
without a checkout; share tickets let a link travel without carrying a
write-capable credential.

## GET /v1/lens/{id}/render

Run a lens or workspace node and render its view tree:

```
GET /v1/lens/{id}/render?format=html|text|json
```

`html` is the default; `text` renders for a terminal; `json` returns the raw
view tree. The render is strictly **read-only** — no action forms; writes
stay with [`/v1/nodes`](/reference/api/writes/) and the MCP tools.

Auth is either the caller's bearer header or a signed read-only **render
ticket** for shared links (a browser link cannot carry an `Authorization`
header). A `?ticket=<blob>` query parameter is accepted once and exchanged
via a 302 for an HttpOnly `spor_render_ticket` cookie, keeping the ticket out
of URLs, logs, and view-to-view hrefs. The ticket binds the viewer to the
recorded sharer, and the render shows a "Viewing as &lt;sharer&gt;" banner.

There is no `?token=<PAT>` sharing path — it was removed so a shared link can
never carry a write-capable credential.

## POST /v1/lens/{id}/ticket

Mint a signed, expiring, read-only render ticket for the lens or workspace,
recording the authenticated caller as the sharer:

```bash
curl -s https://api.sporhq.io/v1/lens/lens-release-board/ticket \
  -H "Authorization: Bearer $SPOR_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"expires": "14d"}'
```

Returns `{ticket, url, lens_id, sharer_person_id, exp}` — `url` is the
shareable link, ready to paste.

- `expires` is `<N>d` or an ISO date; default `7d`, maximum `30d`.
- The caller must be bound to a person node, else `422 no_person`.
- The ticket carries no write scope and is honored only on the render route.
- Tickets are stateless (signed, not stored): there is no revocation list;
  expiry is the bound.

The CLI front-door is `spor share <lens-id> [--expires <Nd>]`.
