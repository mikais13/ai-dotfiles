---
name: edit-stack
description: Rebase a gh-stack stack or update its pull request descriptions.
disable-model-invocation: true
---

## Shared subroutines

### Load gh-stack mechanics

Before running any `gh stack` command, load and follow the `gh-stack` skill. Never guess flags from memory. Bare `gh stack view` can wait for interactive input. Check the skill's flag table for `rebase`.

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

1. `gh stack view --json` to see current state (`needsRebase`, `isMerged`, etc. per branch).
2. Ask the user what kind of edit to make:
   - rebase a specific branch/range: `gh stack rebase [branch] --upstack` / `--downstack` / plain (whole stack)
   - backfill missing descriptions only (no git changes — shared loop, same as always)
   - **explicitly regenerate** one or more named PRs' descriptions, even if they already have content — this is the *only* place in the whole integration where overwriting existing content is allowed, because it's a deliberate choice made in this command rather than an automatic side effect of `add-to-stack` or `sync-stack`
3. Run the chosen `gh stack rebase` invocation. If it exits with code 3 (conflict), follow the `gh-stack` skill's documented conflict-resolution loop: parse stderr for conflicted file paths, read and resolve them, `git add` the resolved files, `gh stack rebase --continue`; repeat until clean, or `gh stack rebase --abort` if asked to give up.
4. After any rebase, run the fill-missing-descriptions loop by default. If the user asked for explicit regeneration of named PRs in step 2, regenerate those specific ones even though they have content — everything else still follows the normal skip-if-present rule.
5. Report a final `gh stack view --json` summary.
