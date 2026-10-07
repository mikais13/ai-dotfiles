---
name: sync-stack
description: Synchronize and prune a gh-stack stack, then fill missing pull request descriptions.
disable-model-invocation: true
---

## Shared subroutines

### Load gh-stack mechanics

Before running any `gh stack` command, load and follow the `gh-stack` skill. Never guess flags from memory. Check its documentation for the exact `sync` behavior and flags.

### Fill-missing-descriptions loop

Given the `branches` array from a fresh `gh stack view --json`, for each entry that has a `pr.number`:

1. `gh pr view <number> --json body` — if `body` is non-empty and doesn't look like a bare auto-generated stub, **skip this PR**. Never overwrite existing content here — only true gaps get filled.
2. Otherwise, resolve this branch's actual parent **branch name** via `gh pr view <number> --json baseRefName` — do NOT use `gh stack view --json`'s `base` field (that's the parent's HEAD SHA at last sync, not a branch name).
3. Diff against that real base: `git log <baseRefName>...<branch> --oneline`, `git diff <baseRefName>...<branch>`.
4. Load the `pr-description` skill with `base branch: <baseRefName>`.
5. Generate a semantic-commit-style title (`type(scope): description`) and apply both: `gh pr edit <number> --title "<title>" --body "$(cat <<'EOF'
<description>

EOF
)"`.

## Procedure

1. `gh stack view --json` for current state.
2. Run `gh stack sync --prune` for the routine path. It fetches, reconciles the remote stack, fast-forwards trunk, rebases dependent branches, pushes, synchronizes pull request state, updates the stack object, and prunes merged branches. This routine path does not need a confirmation gate.
   - If sync reports a diverged local/remote stack, it aborts non-interactively with `ℹ Sync aborted` — report this to the user rather than retrying; resolving a divergence requires `unstack` + re-`init`, which is a structural decision the user should make explicitly (treat as a `edit-stack` follow-up, not something to do automatically here).
   - If sync exits 3 (rebase conflict), follow the `gh-stack` skill's documented conflict-resolution loop: parse stderr for conflicted file paths, resolve them, `git add`, `gh stack rebase --continue`.
3. Run the fill-missing-descriptions loop afterward — new commits from the rebase don't change already-filled bodies, only genuinely empty ones get generated.
4. Report a final `gh stack view --json` summary, calling out anything pruned or merged.
