---
name: merge-stack
description: Merge all or part of a gh-stack stack into trunk with explicit confirmation.
disable-model-invocation: true
---

## Shared subroutine

### Load gh-stack mechanics

Before running any `gh stack` command, load and follow the `gh-stack` skill. Never guess flags from memory. Check its documentation for the exact `merge` scope and method flags.

## Procedure

The highest blast-radius action in this integration — it lands PRs into trunk. Always confirm before running, unlike `sync-stack`'s happy path.

1. `gh stack view --json` for current state. Surface which branches are open/mergeable and flag any with `needsRebase: true` — merging over an out-of-date stack risks the base-branch mismatch the CLI itself would otherwise catch, so don't proceed if `needsRebase` is set anywhere in scope; tell the user to run `edit-stack` or `sync-stack` first.
2. Ask the user to confirm:
   - scope: merge the whole stack, or only up to a specific PR#/stack# (`gh stack merge <pr#> --yes` merges everything up to and including that PR; `gh stack merge <stack#> --yes` needs no local checkout)
   - method: `--squash` / `--rebase` / `--merge` / `--merge-method <method>` (omit to use the last-used method)
3. Run `gh stack merge --yes` with the confirmed scope and method flags. The merge is all-or-nothing — if any PR can't merge, none are, and the CLI reports why.
4. Report the result (which PRs merged, final state) from a post-merge `gh stack view --json`.
