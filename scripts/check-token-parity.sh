#!/usr/bin/env bash
#
# Verify the vendored Spor design tokens have not drifted.
#
# spor-docs vendors src/styles/tokens.css as a BYTE-IDENTICAL copy of the
# canonical Spor design tokens (decision: dec-spor-web-vendor-design-tokens —
# the same vendoring contract the marketing site uses). This check enforces
# that contract so the copy cannot silently drift.
#
# It compares the SHA-256 of src/styles/tokens.css against the fingerprint
# recorded at sync time in src/styles/tokens.css.sha256. That fingerprint IS
# the hash of the canonical tokens — scripts/sync-tokens.sh writes it straight
# from the canonical source. CI runners only ever have the public spor-docs
# checkout, never the canonical repo, so the check is self-contained by design
# and references no private path.
#
# Exit 0 = in parity.  Exit 1 = drift.  Exit 2 = misconfigured.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
target="$root/src/styles/tokens.css"
fingerprint="$root/src/styles/tokens.css.sha256"

err() { printf '%s\n' "$@" >&2; }

[ -f "$target" ]      || { err "::error::missing vendored tokens: $target"; exit 2; }
[ -f "$fingerprint" ] || { err "::error::missing parity fingerprint: $fingerprint — run scripts/sync-tokens.sh to create it"; exit 2; }

sha256_of() {
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "$1" | awk '{print $1}'
  else
    err "::error::neither sha256sum nor shasum is available"; exit 2
  fi
}

expected="$(awk 'NF{print $1; exit}' "$fingerprint")"
actual="$(sha256_of "$target")"

if [ "$expected" != "$actual" ]; then
  err "::error::Design-token parity check FAILED — src/styles/tokens.css has drifted from the canonical Spor design tokens."
  err ""
  err "  expected (canonical fingerprint): $expected"
  err "  actual   (vendored copy):         $actual"
  err ""
  err "src/styles/tokens.css is a verbatim vendored copy and must not be hand-edited."
  err "Site-specific styling belongs in src/styles/theme.css, which maps the tokens"
  err "onto Starlight's variables. To pick up a legitimate canonical token change,"
  err "a maintainer re-syncs from canonical:"
  err "    scripts/sync-tokens.sh <path-to-canonical>/design/tokens.css"
  exit 1
fi

printf 'Design-token parity OK: src/styles/tokens.css matches the recorded canonical fingerprint (%s).\n' "$expected"
