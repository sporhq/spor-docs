#!/usr/bin/env bash
#
# Prose lint: fail if any docs page under src/content/docs/ uses an
# exclamation mark or emoji outside of code. This is the markdown-aware half
# of the style guide's voice rule "no exclamation marks, no emoji"
# (scripts/style-denylist.txt and check-style.sh cover phrase-based rules —
# a phrase grep alone would false-positive on code samples, so this pass
# first strips YAML frontmatter, fenced and indented code blocks, and inline
# code spans, then scans what's left). Invoked by scripts/check-style.sh;
# run it directly with:
#
#   scripts/check-prose.sh
#
# Exit 0 = clean.  Exit 1 = a violation was found.  Exit 2 = misconfigured.
set -euo pipefail

root="$(cd "$(dirname "$0")/.." && pwd)"
content="$root/src/content/docs"
[ -d "$content" ] || { echo "::error::missing $content" >&2; exit 2; }

# Named Unicode ranges: Misc Symbols & Pictographs, Emoticons, Transport &
# Map Symbols, Supplemental Symbols & Pictographs, and variation selectors.
# The last range matters on its own: a glyph like a warning sign pairs a
# base character outside these blocks with a trailing variation selector,
# so the selector alone is what catches it.
emoji_pattern='[\x{1F300}-\x{1F5FF}\x{1F600}-\x{1F64F}\x{1F680}-\x{1F6FF}\x{1F900}-\x{1FAFF}\x{FE00}-\x{FE0F}]'

# Blank out everything that isn't prose — rather than removing it — so line
# numbers in the output still match the source file: YAML frontmatter (the
# leading `---` ... `---` block), fenced code blocks (``` or ~~~, tracking
# the fence's own character and length so a shorter or different fence
# nested inside doesn't close it early), and indented code blocks (4 spaces
# or a tab). On what's left, drop single-line HTML comments and the leading
# `!` of markdown image syntax, and strip inline code spans — tracked with
# an in_code flag that carries across lines, because a span opened by a
# single backtick commonly closes on the next line (a wrapped JSON example
# like `` `{foo,\nbar}` `` recurs throughout the API reference).
strip_non_prose() {
  awk '
    BEGIN { in_fence = 0; fence_char = ""; fence_len = 0; in_fm = 0; in_code = 0 }
    {
      line = $0
      if (FNR == 1 && line == "---") { in_fm = 1; in_code = 0; print ""; next }
      if (in_fm) { if (line == "---") in_fm = 0; print ""; next }

      # An inline code span never crosses a block boundary in real markdown
      # (a stray unclosed backtick just renders as a literal character), so
      # in_code resets at every one of these — otherwise one malformed line
      # could blank out everything after it for the rest of the file.
      if (match(line, /^ {0,3}(```+|~~~+)/)) {
        fence_str = substr(line, RSTART, RLENGTH)
        sub(/^ */, "", fence_str)
        this_char = substr(fence_str, 1, 1)
        this_len = length(fence_str)
        if (in_fence) {
          if (this_char == fence_char && this_len >= fence_len) {
            in_fence = 0; in_code = 0; print ""; next
          }
        } else {
          in_fence = 1; fence_char = this_char; fence_len = this_len; in_code = 0
          print ""; next
        }
      }

      if (in_fence) { print ""; next }
      if (match(line, /^(    |\t)/)) { in_code = 0; print ""; next }

      # Split on single backticks: with k backticks on the line, this gives
      # k+1 parts, alternating prose/code starting from the carried-in
      # in_code state. Keep only the parts that land in a prose state.
      n = split(line, parts, "`")
      out = ""
      state = in_code
      for (i = 1; i <= n; i++) {
        if (!state) out = out parts[i]
        if (i < n) state = !state
      }
      in_code = state

      gsub(/<!--.*-->/, "", out)
      gsub(/!\[/, "[", out)
      print out
    }
  ' "$1"
}

# Run one grep -n detector over $stripped and append any hits to $hits as
# file:line:kind:content report lines. Treats a real grep error (exit >1,
# not just "no match") as fatal instead of letting `|| true` swallow it —
# the same distinction check-style.sh's git grep makes (943ce23 established
# the guard for the "no match" case; a genuine engine error still must not
# read as a clean pass).
scan() {
  local kind="$1"; shift
  set +e
  local out status
  out="$("$@" <<<"$stripped")"
  status=$?
  set -e
  if [ "$status" -gt 1 ]; then
    echo "::error::grep failed (status $status) scanning $rel for $kind" >&2
    exit 2
  fi
  if [ -n "$out" ]; then
    hits+="$(printf '%s\n' "$out" | awk -F: -v file="$rel" -v kind="$kind" '{ ln = $1; sub(/^[^:]*:/, ""); print file ":" ln ": " kind ": " $0 }')"$'\n'
  fi
}

# Excluded like the style guide is from check-style.sh's phrase grep: this
# page documents the "no exclamation marks, no emoji" rule and may need a
# literal example of what it bans.
cd "$content"
hits=""
while IFS= read -r -d '' f; do
  rel="src/content/docs/${f#./}"
  [ "$rel" = "src/content/docs/contributing/style-guide.md" ] && continue
  stripped="$(strip_non_prose "$f")"

  scan "exclamation mark" grep -nF '!'
  # -P's \x{...} escapes need a UTF-8 locale to parse as codepoints rather
  # than raw bytes; force one instead of trusting the ambient environment,
  # so this can't silently stop matching anything under e.g. LC_ALL=C.
  scan "emoji" env LC_ALL=C.UTF-8 grep -nP "$emoji_pattern"
done < <(find . \( -name '*.md' -o -name '*.mdx' \) -print0)

if [ -n "$hits" ]; then
  {
    echo "::error::Prose lint FAILED — the following lines use an exclamation mark or emoji outside of code."
    echo "The docs voice never uses exclamation marks, emoji, or rhetorical headings."
    echo "See the style guide (/contributing/style-guide/) for the voice rules."
    echo
    printf '%s' "$hits"
  } >&2
  exit 1
fi

echo "Prose lint OK: no exclamation marks or emoji in docs prose."
