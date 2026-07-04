#!/usr/bin/env bash
#
# Style lint: fail if any docs page under src/content/docs/ contains a phrase
# from scripts/style-denylist.txt (marketing intensifiers, persuasion
# patterns). This is the mechanical subset of the style guide's voice rules;
# the guide itself is the contract. Runs in CI on every PR; run it locally
# with:
#
#   scripts/check-style.sh
#
# Exit 0 = clean.  Exit 1 = banned phrase found.  Exit 2 = misconfigured.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
denylist="$root/scripts/style-denylist.txt"
[ -f "$denylist" ] || { echo "::error::missing $denylist" >&2; exit 2; }

# Build one alternation from the non-comment, non-blank lines.
pattern="$(grep -Ev '^\s*(#|$)' "$denylist" | paste -sd'|' -)"
[ -n "$pattern" ] || { echo "::error::denylist is empty" >&2; exit 2; }

cd "$root"
# The style guide legitimately names the banned words as examples.
hits="$(git grep -I -i -n -E "$pattern" -- \
  'src/content/docs' \
  ':(exclude)src/content/docs/contributing/style-guide.md' \
  || true)"

if [ -n "$hits" ]; then
  {
    echo "::error::Style lint FAILED — the following lines use a banned phrase."
    echo "The docs voice is calm and precise; it never persuades. Rewrite the"
    echo "passage as a checkable claim about what the tool does."
    echo "See scripts/style-denylist.txt for the banned phrases and the"
    echo "style guide (/contributing/style-guide/) for the voice rules."
    echo
    echo "$hits"
  } >&2
  exit 1
fi

echo "Style lint OK: no banned phrases in the docs pages."
