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

# Build one alternation from the non-comment, non-blank lines. The || true
# keeps a comments-only denylist flowing into the explicit guard below
# instead of tripping set -e inside the substitution.
pattern="$(grep -Ev '^\s*(#|$)' "$denylist" | paste -sd'|' - || true)"
[ -n "$pattern" ] || { echo "::error::denylist is empty" >&2; exit 2; }

cd "$root"
# --untracked also scans new files that haven't been `git add`ed yet, so this
# matches what CI enforces on tracked files after they land in a commit.
# The lint machinery itself legitimately names the banned terms.
hits="$(git grep -I -i -n -E --untracked "$pattern" -- \
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
