#!/usr/bin/env bash
#
# Boundary lint: fail if any tracked file leaks a term from
# scripts/boundary-denylist.txt (private repository paths, server deployment
# internals, or real graph data). Runs in CI on every PR; run it locally with:
#
#   scripts/check-boundary.sh
#
# Exit 0 = clean.  Exit 1 = leak found.  Exit 2 = misconfigured.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
denylist="$root/scripts/boundary-denylist.txt"
[ -f "$denylist" ] || { echo "::error::missing $denylist" >&2; exit 2; }

# Build one alternation from the non-comment, non-blank lines.
pattern="$(grep -Ev '^\s*(#|$)' "$denylist" | paste -sd'|' -)"
[ -n "$pattern" ] || { echo "::error::denylist is empty" >&2; exit 2; }

cd "$root"
# The lint machinery itself legitimately names the banned terms.
hits="$(git grep -I -i -n -E "$pattern" -- \
  ':(exclude)scripts/boundary-denylist.txt' \
  ':(exclude)scripts/check-boundary.sh' \
  || true)"

if [ -n "$hits" ]; then
  {
    echo "::error::Boundary lint FAILED — the following lines name private internals or real graph data."
    echo "The public docs describe the Spor server abstractly and use fictional example data."
    echo "See scripts/boundary-denylist.txt for the banned terms."
    echo
    echo "$hits"
  } >&2
  exit 1
fi

echo "Boundary lint OK: no private paths, server internals, or real graph data in tracked files."
