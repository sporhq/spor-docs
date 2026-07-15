#!/usr/bin/env bash
#
# Redirect table lint: fail on entries in astro.config.mjs's `redirects` map
# that have gone stale. Nothing else catches this -- starlight-links-validator
# only validates links that already appear in markdown content, so a
# redirects entry nobody links to is invisible to it. Checks:
#
#   - unparseable entry: the entry isn't a flat `'/src': '/dst',` string
#     pair (e.g. Astro's object-form `{ destination, status }`, or a
#     multi-line value) -- this script only understands flat pairs, so it
#     fails loudly here instead of silently skipping the entry (and, if
#     the entry spans multiple lines, everything written after it).
#   - stale source: a live content page now exists at the redirect's source,
#     so the redirect shadows real content instead of getting deleted when
#     the page was restored.
#   - duplicate source: the same source key appears twice, so the later
#     entry silently wins and the earlier one is dead weight.
#   - broken target: the destination resolves to neither a live page, an
#     external URL, nor another redirect, so visitors land on a 404.
#   - redirect chain: the destination is itself another redirect's source,
#     so visitors take two hops instead of landing directly on the final
#     page.
#
# Runs in CI on every PR; run it locally with:
#
#   scripts/check-redirects.sh
#
# Exit 0 = clean.  Exit 1 = a problem was found.  Exit 2 = misconfigured.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
config="$root/astro.config.mjs"
content="$root/src/content/docs"

err() { printf '%s\n' "$@" >&2; }

# Normalize a URL path for comparison, writing the result into the caller's
# named variable (avoids a subshell per call). Strips a hash fragment and
# any trailing slash: Astro's default trailingSlash mode ('ignore') treats
# `/foo` and `/foo/` as the same route, so redirect sources (written
# without a trailing slash) and content pages (enumerated with one) must
# be compared on equal footing. The root path collapses to "/".
normalize() {
  local -n out_ref=$2
  local p="${1%%#*}"
  p="${p%/}"
  [ -z "$p" ] && p="/"
  out_ref="$p"
}

is_external() { [[ "$1" =~ ^[a-zA-Z][a-zA-Z0-9+.-]*:// ]]; }

[ -f "$config" ] || { err "::error::missing $config"; exit 2; }
[ -d "$content" ] || { err "::error::missing $content"; exit 2; }

grep -qE 'redirects:[[:space:]]*\{' "$config" || {
  err "::error::no \`redirects: {\` block found in $config"
  exit 2
}

# Isolate the `redirects: { ... }` block by brace depth, not by "the next
# line starting with `}`" -- a naive scan like that ends the block early at
# the closing brace of any multi-line, object-shaped entry value nested
# inside it, silently dropping every entry written after it.
redirect_block="$(awk '
  BEGIN { depth = 0; in_block = 0 }
  in_block == 0 && /redirects:[[:space:]]*\{/ { in_block = 1; depth = 1; next }
  in_block {
    line = $0
    opens = gsub(/\{/, "{", line)
    closes = gsub(/\}/, "}", line)
    if (depth + opens - closes <= 0) { in_block = 0; exit }
    depth += opens - closes
    print $0
  }
' "$config")"

declare -A live_pages=()
while IFS= read -r f; do
  f="${f#./}"
  rel="${f%.mdx}"; rel="${rel%.md}"
  if [ "$rel" = "index" ]; then
    p="/"
  elif [[ "$rel" == */index ]]; then
    p="/${rel%index}"
  else
    p="/$rel/"
  fi
  normalize "$p" norm
  live_pages["$norm"]=1
done < <(cd "$content" && find . \( -name '*.md' -o -name '*.mdx' \))

declare -A redirect_target=()      # normalized source -> normalized target
declare -A redirect_target_raw=()  # normalized source -> target as written (keeps hash)
unparseable=()
duplicates=()

while IFS= read -r line; do
  # Blank lines and full-line comments are structural, not entries.
  [[ "$line" =~ ^[[:space:]]*$ ]] && continue
  [[ "$line" =~ ^[[:space:]]*// ]] && continue

  if [[ "$line" =~ ^[[:space:]]*\'([^\']+)\':[[:space:]]*\'([^\']+)\',?[[:space:]]*$ ]]; then
    src="${BASH_REMATCH[1]}"
    dst="${BASH_REMATCH[2]}"
    normalize "$src" norm_src
    if [ -n "${redirect_target[$norm_src]:-}" ]; then
      duplicates+=("$src")
    fi
    normalize "$dst" norm_dst
    redirect_target["$norm_src"]="$norm_dst"
    redirect_target_raw["$norm_src"]="$dst"
  else
    unparseable+=("$line")
  fi
done <<<"$redirect_block"

stale=()
broken=()
chains=()
for src in "${!redirect_target[@]}"; do
  if [ -n "${live_pages[$src]:-}" ]; then
    stale+=("$src")
  fi

  dst="${redirect_target[$src]}"
  if is_external "$dst"; then
    continue
  elif [ -n "${live_pages[$dst]:-}" ]; then
    continue
  elif [ -n "${redirect_target[$dst]:-}" ]; then
    chains+=("$src -> $dst -> ${redirect_target[$dst]}")
  else
    broken+=("$src -> ${redirect_target_raw[$src]}")
  fi
done

if [ ${#unparseable[@]} -gt 0 ] || [ ${#stale[@]} -gt 0 ] || [ ${#duplicates[@]} -gt 0 ] || [ ${#broken[@]} -gt 0 ] || [ ${#chains[@]} -gt 0 ]; then
  {
    echo "::error::Redirect table lint FAILED -- astro.config.mjs's redirects map has a problem."
    echo
    if [ ${#unparseable[@]} -gt 0 ]; then
      echo "Unparseable entries (only flat '/src': '/dst', string pairs are understood):"
      printf '%s\n' "${unparseable[@]}" | sort -u | sed 's/^/  - /'
      echo
    fi
    if [ ${#stale[@]} -gt 0 ]; then
      echo "Stale sources (a live page now exists at the redirect's source -- delete the redirect):"
      printf '%s\n' "${stale[@]}" | sort -u | sed 's/^/  - /'
      echo
    fi
    if [ ${#duplicates[@]} -gt 0 ]; then
      echo "Duplicate sources (later entry silently wins -- remove the redundant one):"
      printf '%s\n' "${duplicates[@]}" | sort -u | sed 's/^/  - /'
      echo
    fi
    if [ ${#broken[@]} -gt 0 ]; then
      echo "Broken targets (destination is neither a live page, an external URL, nor another redirect):"
      printf '%s\n' "${broken[@]}" | sort -u | sed 's/^/  - /'
      echo
    fi
    if [ ${#chains[@]} -gt 0 ]; then
      echo "Redirect chains (point the source directly at the final destination):"
      printf '%s\n' "${chains[@]}" | sort -u | sed 's/^/  - /'
      echo
    fi
  } >&2
  exit 1
fi

printf 'Redirect table OK: %s entries, no unparseable entries, stale sources, duplicates, broken targets, or chains.\n' "${#redirect_target[@]}"
