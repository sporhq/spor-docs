#!/bin/sh
# dispatch-worktree-setup.sh — prep a freshly-created `spor dispatch --worktree`
# worktree of spor-docs so `npm run build` and every scripts/check-*.sh work
# with no manual step.
#
# `spor dispatch` runs this with cwd = the new worktree and these in the env:
#   SPOR_WORKTREE        absolute path of the worktree (== cwd)
#   SPOR_MAIN_CHECKOUT   the durable main checkout the worktree was cut from
#                        (unused here on purpose — see below)
#   SPOR_DISPATCH_SLUG   the resolved project slug
#   SPOR_DISPATCH_NODE   the dispatched node id (if any)
#
# Wired via spor-docs's committed .spor.json (a RELATIVE worktreeSetup path,
# so it stays machine-portable):
#   { "dispatch": { "worktree": true, "worktreeSetup": "scripts/dispatch-worktree-setup.sh" } }
#
# A symlinked node_modules used to point straight at the main checkout's
# node_modules for speed. That main checkout is a LIVE, shared, mutable
# directory — other dispatches run `npm install`/`npm ci` in it, and a
# worktree reading through the symlink can observe it mid-mutation (a
# package's package.json rewritten but its nested files not yet extracted).
# That already caused one confirmed race on this repo's .spor.json
# (dec-spor-docs-worktree-setup-hook-dirty-checkout-race); the same failure
# mode on node_modules is what produced `astro sync`'s
# "Tsconfig not found astro/tsconfigs/strict" — astro's package.json
# resolves fine but its tsconfigs/*.json export target is transiently
# missing/being rewritten underneath. `npm ls --depth=0` only checks the
# declared dependency graph, not file-level completeness, so it can pass
# right through a state like that.
#
# The only way to stop a worktree from depending on that shared, mutable
# state is to never read through it: always give the worktree its own real,
# private node_modules via `npm ci` (offline-preferred, so it's just a cache
# extraction — no network round trip — whenever the lockfile's packages are
# already cached from the main checkout's own installs).
set -eu

wt="${SPOR_WORKTREE:?SPOR_WORKTREE not set — run me via spor dispatch}"

cd "$wt"

# `npm ci` would remove a stray node_modules symlink itself (it unlinks
# rather than recursing into a symlink's target), but make that removal
# explicit rather than relying on npm's own symlink handling.
if [ -L node_modules ]; then
  rm node_modules
fi

echo "dispatch-worktree-setup: installing a private node_modules in the worktree"
npm ci --prefer-offline
