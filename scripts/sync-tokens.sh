#!/usr/bin/env bash
#
# Re-sync the vendored Spor design tokens from canonical and refresh the parity
# fingerprint that CI enforces (scripts/check-token-parity.sh).
#
# Run by a maintainer who has the canonical tokens checked out locally. The
# canonical path is supplied by the caller and is intentionally NOT hardcoded:
# spor-docs is a PUBLIC repo and its source names no private-repo paths.
#
#   scripts/sync-tokens.sh <path-to-canonical>/design/tokens.css
#   SPOR_CANONICAL_TOKENS=<path>/design/tokens.css scripts/sync-tokens.sh
#
# It (1) copies canonical over src/styles/tokens.css verbatim, (2) records its
# SHA-256 in src/styles/tokens.css.sha256, and (3) runs the parity check.
# Commit both files together.
set -euo pipefail

canonical="${1:-${SPOR_CANONICAL_TOKENS:-}}"
if [ -z "$canonical" ]; then
  printf 'usage: %s <path-to-canonical>/design/tokens.css\n' "$0" >&2
  printf '   or: SPOR_CANONICAL_TOKENS=<path>/design/tokens.css %s\n' "$0" >&2
  exit 2
fi
[ -f "$canonical" ] || { printf 'error: canonical tokens not found at: %s\n' "$canonical" >&2; exit 2; }

root="$(cd "$(dirname "$0")/.." && pwd)"
target="$root/src/styles/tokens.css"
fingerprint="$root/src/styles/tokens.css.sha256"

cp "$canonical" "$target"

if command -v sha256sum >/dev/null 2>&1; then
  sha256sum "$target" | awk '{print $1}' > "$fingerprint"
else
  shasum -a 256 "$target" | awk '{print $1}' > "$fingerprint"
fi

"$root/scripts/check-token-parity.sh"
printf 'Synced tokens from %s and refreshed the fingerprint. Commit both files together.\n' "$canonical"
