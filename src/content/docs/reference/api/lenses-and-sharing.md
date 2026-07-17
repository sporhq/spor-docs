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

A lens can also offer a declarative action on a rendered item (a status
button on a board card, say). Selecting one is a write, but there is no REST
route for it — `apply_lens_action` is reachable only as an
[MCP tool call](/reference/mcp/tools/#apply_lens_action) from the
[widget](/reference/mcp/widget/) itself. A REST-only client mutates the
target node directly through [Writes](/reference/api/writes/) instead.

## POST /v1/lens/{id}/ticket

Mint a signed, expiring, read-only render ticket for the lens or workspace,
recording the authenticated caller as the sharer:

```sh
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

### `url` on an MCP-only host

An MCP-only host doesn't serve `/v1/lens/{id}/render` (it 404s), so a relative
link there would be dead on arrival. If that host is configured with a
`SPOR_APP_URL` (pointing at the separate app host that renders lenses for
browsers), the minted `url` is instead the absolute
`${SPOR_APP_URL}/views/{id}?ticket=...` — still ready to paste. Without
`SPOR_APP_URL` set, the response falls back to the prior relative shape.

The app host's `GET /views/{id}` exchanges that `?ticket=` exactly once into
the same HttpOnly `spor_render_ticket` cookie described above, then forwards
the ticket to api as the credential on its own render fetch. One rule flips
relative to the direct render route: on the app host a **live session
outranks the ticket cookie** — a signed-in visitor sees their own session,
never the sharer's view — so a pasted link can never silently pin a
signed-in user's session to the sharer's identity.
