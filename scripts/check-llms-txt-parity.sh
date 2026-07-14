#!/usr/bin/env bash
#
# llms.txt parity lint: fail if public/llms.txt has drifted from the docs
# content collection — every content page must have a line in llms.txt, and
# every docs.sporhq.io URL in llms.txt must point at a page that still
# exists. llms.txt is hand-maintained, so nothing else catches this; without
# it the index silently rots as pages are added, renamed, or removed. Runs
# in CI on every PR; run it locally with:
#
#   scripts/check-llms-txt-parity.sh
#
# The site root ("/") is intentionally exempt: per the llms.txt convention,
# the file's own opening blurb stands in for the homepage, so the homepage
# is not expected to also appear as a body link.
#
# Exit 0 = in parity.  Exit 1 = drift.  Exit 2 = misconfigured.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
content="$root/src/content/docs"
llms="$root/public/llms.txt"

err() { printf '%s\n' "$@" >&2; }

[ -d "$content" ] || { err "::error::missing $content"; exit 2; }
[ -f "$llms" ]    || { err "::error::missing $llms"; exit 2; }

# Every *.md/*.mdx page maps to its Starlight URL: an `index` file's URL is
# its directory; any other file's URL is its own path plus a trailing slash.
pages="$(cd "$content" && find . \( -name '*.md' -o -name '*.mdx' \) | sed 's#^\./##' | while read -r f; do
  rel="${f%.mdx}"; rel="${rel%.md}"
  if [ "$rel" = "index" ]; then
    continue # the site root — exempt, see header comment
  elif [[ "$rel" == */index ]]; then
    echo "/${rel%index}"
  else
    echo "/$rel/"
  fi
done | sort -u)"

[ -n "$pages" ] || { err "::error::no content pages found under $content"; exit 2; }

urls="$(grep -oE 'https://docs\.sporhq\.io[^)[:space:]]*' "$llms" | sed -E 's#^https://docs\.sporhq\.io##; s/#.*$//' | sort -u)"

[ -n "$urls" ] || { err "::error::no docs.sporhq.io URLs found in $llms"; exit 2; }

missing_pages="$(comm -23 <(printf '%s\n' "$pages") <(printf '%s\n' "$urls"))"
orphaned_urls="$(comm -13 <(printf '%s\n' "$pages") <(printf '%s\n' "$urls"))"

if [ -n "$missing_pages" ] || [ -n "$orphaned_urls" ]; then
  {
    echo "::error::llms.txt parity lint FAILED — public/llms.txt has drifted from src/content/docs."
    echo "Every content page needs a line in llms.txt, and every docs.sporhq.io URL in llms.txt"
    echo "must resolve to a page that still exists."
    echo
    if [ -n "$missing_pages" ]; then
      echo "Content pages with no llms.txt line:"
      echo "$missing_pages" | sed 's/^/  - /'
    fi
    if [ -n "$orphaned_urls" ]; then
      echo "llms.txt URLs with no matching content page (orphaned):"
      echo "$orphaned_urls" | sed 's/^/  - /'
    fi
  } >&2
  exit 1
fi

count="$(printf '%s\n' "$pages" | grep -c .)"
printf 'llms.txt parity OK: all %s content page(s) have a matching llms.txt line, no orphaned URLs.\n' "$count"
