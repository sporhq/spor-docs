#!/usr/bin/env bash
#
# View-tools parity lint: fail if widget.md's enumeration of widget-attachable
# view-carrying tools drifts from tools.md.
#
# tools.md is the single source of truth: each tool is documented there once,
# under "## Views", and a tool counts as view-carrying when its heading is
# immediately preceded by a `<!-- view-carrying-tool -->` marker. widget.md's
# opening paragraph names the same set for a reader landing there first; its
# enumeration is bounded by `<!-- view-carrying-tools:start/end -->` markers
# so this check knows exactly which links to compare instead of guessing at
# prose. Add a new view-carrying tool by marking it in tools.md and linking it
# in widget.md's bounded block — this check fails loudly if you forget either
# side. Runs in CI on every PR; run it locally with:
#
#   scripts/check-view-tools-parity.sh
#
# Exit 0 = in parity.  Exit 1 = drift.  Exit 2 = misconfigured.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
tools="$root/src/content/docs/reference/mcp/tools.md"
widget="$root/src/content/docs/reference/mcp/widget.md"

err() { printf '%s\n' "$@" >&2; }

[ -f "$tools" ]  || { err "::error::missing $tools"; exit 2; }
[ -f "$widget" ] || { err "::error::missing $widget"; exit 2; }

# tools.md: a tool is "view-carrying" when its `### `name`` heading is
# immediately preceded by the marker comment.
canonical="$(awk '
  /<!-- view-carrying-tool -->/ { want = 1; next }
  want && /^### `/ {
    name = $0
    sub(/^### `/, "", name)
    sub(/`.*/, "", name)
    print name
    want = 0
  }
' "$tools" | sort -u)"

[ -n "$canonical" ] || { err "::error::no <!-- view-carrying-tool --> markers found in $tools"; exit 2; }

# widget.md: the enumerated set is whatever tools are linked between the
# explicit start/end markers.
enumerated="$(awk '
  /<!-- view-carrying-tools:start -->/ { in_block = 1; next }
  /<!-- view-carrying-tools:end -->/   { in_block = 0 }
  in_block
' "$widget" | { grep -oE '/reference/mcp/tools/#[A-Za-z0-9_]+' || true; } | sed -E 's#^/reference/mcp/tools/##; s/^#//' | sort -u)"

[ -n "$enumerated" ] || { err "::error::no view-carrying-tools:start/end block found in $widget"; exit 2; }

missing_from_widget="$(comm -23 <(printf '%s\n' "$canonical") <(printf '%s\n' "$enumerated"))"
stale_in_widget="$(comm -13 <(printf '%s\n' "$canonical") <(printf '%s\n' "$enumerated"))"

if [ -n "$missing_from_widget" ] || [ -n "$stale_in_widget" ]; then
  {
    echo "::error::View-tools parity lint FAILED — widget.md has drifted from tools.md."
    echo "tools.md (marked <!-- view-carrying-tool -->) is the source of truth for which tools"
    echo "carry a widget-attachable view tree; widget.md's bounded enumeration must list exactly"
    echo "the same set."
    echo
    if [ -n "$missing_from_widget" ]; then
      echo "Marked view-carrying in tools.md but missing from widget.md's enumeration:"
      echo "$missing_from_widget" | sed 's/^/  - /'
    fi
    if [ -n "$stale_in_widget" ]; then
      echo "Linked in widget.md's enumeration but not marked view-carrying in tools.md:"
      echo "$stale_in_widget" | sed 's/^/  - /'
    fi
  } >&2
  exit 1
fi

count="$(printf '%s\n' "$canonical" | grep -c .)"
printf 'View-tools parity OK: widget.md matches the %s tool(s) marked view-carrying in tools.md.\n' "$count"
