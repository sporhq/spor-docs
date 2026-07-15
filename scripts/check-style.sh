#!/usr/bin/env bash
#
# Style lint: fail if any docs page under src/content/docs/ contains a phrase
# from scripts/style-denylist.txt (marketing intensifiers, persuasion
# patterns), then hand off to scripts/check-prose.sh for the markdown-aware
# pass (exclamation marks and emoji), which needs to strip code before
# scanning rather than grep raw lines. This is the mechanical subset of the
# style guide's voice rules; the guide itself is the contract. Runs in CI on
# every PR; run it locally with:
#
#   scripts/check-style.sh
#
# Exit 0 = clean.  Exit 1 = a banned phrase, or an exclamation mark/emoji
# found by the check-prose.sh handoff.  Exit 2 = misconfigured.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
denylist="$root/scripts/style-denylist.txt"
[ -f "$denylist" ] || { echo "::error::missing $denylist" >&2; exit 2; }

# Build one alternation from the non-comment, non-blank lines. The || true
# keeps a comments-only denylist flowing into the explicit guard below
# instead of tripping set -e inside the substitution.
pattern="$(grep -Ev '^\s*(#|$)' "$denylist" | paste -sd'|' - || true)"
[ -n "$pattern" ] || { echo "::error::denylist is empty" >&2; exit 2; }

cd "$root"
# The style guide legitimately names the banned words as examples.
set +e
hits="$(git grep -I -i -n -E "$pattern" -- \
  'src/content/docs' \
  ':(exclude)src/content/docs/contributing/style-guide.md')"
grep_status=$?
set -e

# git grep exits 0 (match), 1 (no match), or >1 (real error, e.g. a malformed
# pattern from style-denylist.txt) — don't let a real error masquerade as a
# clean pass.
if [ "$grep_status" -gt 1 ]; then
  echo "::error::git grep failed (status $grep_status) — check scripts/style-denylist.txt for a malformed pattern" >&2
  exit 2
fi

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

# Hand off to the markdown-aware prose pass (exclamation marks, emoji);
# exec so its exit code becomes this script's. Invoked via `bash` rather
# than run directly so this doesn't depend on check-prose.sh keeping its
# own executable bit.
exec bash "$root/scripts/check-prose.sh"
