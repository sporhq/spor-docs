#!/bin/sh
# dispatch-worktree-setup.sh — prep a freshly-created `spor dispatch --worktree`
# worktree of spor-docs so `npm run build` and every scripts/check-*.sh work
# with no manual step.
#
# `spor dispatch` runs this with cwd = the new worktree and these in the env:
#   SPOR_WORKTREE        absolute path of the worktree (== cwd)
#   SPOR_MAIN_CHECKOUT   the durable main checkout the worktree was cut from
#   SPOR_DISPATCH_SLUG   the resolved project slug
#   SPOR_DISPATCH_NODE   the dispatched node id (if any)
#
# Wired via spor-docs's committed .spor.json (a RELATIVE worktreeSetup path,
# so it stays machine-portable):
#   { "dispatch": { "worktree": true, "worktreeSetup": "scripts/dispatch-worktree-setup.sh" } }
#
# The main checkout's node_modules has been observed incomplete (missing
# starlight-links-validator — an UNMET DEPENDENCY per `npm ls`), so a plain
# symlink to it can silently hand a worktree an unbuildable tree. Symlink for
# speed when it's there, verify it with `npm ls`, and fall back to a real
# `npm ci` inside the worktree whenever the main checkout can't cover it.
set -eu

main="${SPOR_MAIN_CHECKOUT:?SPOR_MAIN_CHECKOUT not set — run me via spor dispatch}"
wt="${SPOR_WORKTREE:-$PWD}"

cd "$wt"

if [ -d "$main/node_modules" ] && [ ! -e node_modules ]; then
  ln -s "$main/node_modules" node_modules
  echo "dispatch-worktree-setup: linked node_modules -> $main/node_modules"
fi

if ! npm ls --depth=0 >/dev/null 2>&1; then
  echo "dispatch-worktree-setup: node_modules missing or incomplete, running npm ci in the worktree"
  if [ -L node_modules ]; then
    rm node_modules
  fi
  npm ci
fi
