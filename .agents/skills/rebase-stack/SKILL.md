---
name: rebase-stack
description: Align each layer of a gh-stack stack on the head of the layer below, for example after a commit to a middle pull request, then push. Keeps the original base unless the user asks for the latest trunk.
disable-model-invocation: true
compatibility: Requires Git 2.36+, GitHub CLI with the gh-stack extension, and the gh-stack skill.
---

# Rebase a Stack

Each layer must start at the head of the layer below it. A commit to a lower layer, for example review feedback on a middle pull request, breaks this for every layer above it. This skill repairs the chain.

There are two modes:

- **Align mode:** the default. Align the layers with each other. The bottom layer keeps its base, so the stack does not take new trunk commits.
- **Latest-trunk mode:** only when the user or the calling skill asks for the latest trunk. Also rebase the stack onto the newest trunk.

Other stack skills read this file. `absorb-into-stack` runs align mode. `sync-stack` runs latest-trunk mode. Both use step 6 for conflicts.

## 1. Load the Stack State

Load and follow the `gh-stack` skill before you run a `gh stack` command. Do not use flags from memory. Run `gh stack view --json`. If the repository has more than one remote and `remote.pushDefault` is not set, add `--remote <name>` to `gh stack rebase` and `gh stack push`.

The `head` and `base` fields in `gh stack view --json` are saved values. They can be older than the branches. Use `git rev-parse <branch>` for the current tip of a branch.

If a rebase stopped earlier (`git rev-parse --git-path rebase-merge` exists), or a `gh stack` command exits 7, go to step 6.

## 2. Check the Working Tree

- If `git status --porcelain` shows changes, stop. Ask the user to commit or stash them. gh-stack does not stash changes.
- If `git config rerere.enabled` is not `true`, set it. Git then replays a conflict resolution again when the same conflict occurs in a higher layer.

## 3. Get Commits From GitHub

Before you fetch, record the tip of each layer (`git rev-parse <branch>`) for the report.

A layer can have commits on the remote that are not local, for example an accepted review suggestion. Run `git fetch <remote>`. Then compare each layer with `<remote>/<branch>`. If `<remote>/<branch>` does not exist, the layer was never pushed. Skip it.

```bash
git rev-list --left-right --count <branch>...<remote>/<branch>   # <local-only> <remote-only>
```

- **The remote has no commits that the local branch does not have** (`<remote-only>` is 0): do nothing.
- **Only the remote has new commits:** fast-forward the local branch.
  - For the current branch: `git merge --ff-only <remote>/<branch>`
  - For a branch that is checked out in another worktree: `git -C <worktree> merge --ff-only <remote>/<branch>`
  - For another branch: `git fetch <remote> <branch>:<branch>`
- **Both sides have new commits:** run `git cherry <branch> <remote>/<branch>`. A line that starts with `-` is a remote commit that the local branch already has in a rewritten form, for example after an earlier rebase. If all lines start with `-`, keep the local branch. If a line starts with `+`, the remote has new work. Stop and ask the user.

## 4. Check the Chain

Go from the bottom layer to the top layer. The parent of the bottom layer is the trunk. The parent of each other layer is the layer below it.

1. Record the original base: `git merge-base <trunk> <bottom-branch>`.
2. Find each layer that does not contain the tip of its parent: `git merge-base --is-ancestor <parent> <branch>` fails.

If all layers are aligned and the mode is align mode, tell the user that the stack is already aligned. When another skill runs this file, go back to that skill. Otherwise, go to step 8, because a layer can have local commits that are not pushed.

## 5. Rebase

- Align mode: `gh stack rebase --no-trunk`. This rebases each layer onto the head of the layer below it and does not move the bottom layer.
- Latest-trunk mode: `gh stack rebase`. This also fetches the trunk and rebases the bottom layer onto it.

Then do the step that agrees with the result:

- **Exit 0:** go to step 7.
- **Exit 3:** go to step 6.
- **Other exit codes:** use the exit code table in the `gh-stack` skill. If gh-stack reports a dirty worktree in another location, give the user its path. Stop.

## 6. Resolve Conflicts

1. Read the conflicted paths from stderr.
2. For each file, read the commit that the rebase replays (`git show REBASE_HEAD`) and the change on the other side. Keep the intent of both changes.
3. If the intent is not clear, or the resolution changes behavior, ask the user.
4. Run `git add <paths>`, then `gh stack rebase --continue`.
5. Do these steps again until the rebase completes.

Use `gh stack rebase --abort` only when the user asks for it. It restores every branch in the stack.

## 7. Verify

1. Run `gh stack view --json`. No layer can show `needsRebase: true`.
2. Make sure that each parent is an ancestor of its child.
3. In align mode, `git merge-base <trunk> <bottom-branch>` must still equal the original base from step 4.1.
4. If you resolved conflicts, run the fast checks of the project (for example, the type check or unit tests) on each layer that had a conflict, if the project has such checks.

## 8. Push

Run `gh stack push`. It uses `--force-with-lease`. If the remote rejects a branch, report the branch and stop. Do not force the push.

## 9. Report

Run `gh stack view --json` and show a table: branch, old tip, new tip, PR URL, and PR state. If a branch has no `pr` entry, write "No PR" and recommend `/add-to-stack`.

In align mode, if `<remote>/<trunk>` has commits that the bottom layer does not contain, say how many. Recommend `/sync-stack` to move the stack onto them.

## Required Behavior

- Use align mode unless the user or the calling skill asks for the latest trunk.
- Do not change the trunk branch.
- Do not use `gh stack modify`. It works only in an interactive screen.
- Ask the user before you resolve a conflict when you are not sure of the intent.
