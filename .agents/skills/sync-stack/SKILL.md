---
name: sync-stack
description: Sync a gh-stack stack with the latest trunk and GitHub, prune merged branches, and fill missing pull request descriptions.
disable-model-invocation: true
compatibility: Requires Git 2.36+, GitHub CLI with the gh-stack extension, and the gh-stack skill.
---

# Sync a Stack

Use this skill for the routine update, for example after a pull request in the stack merges on GitHub. It moves the stack onto the latest trunk. To align the layers and keep the current base, use `/rebase-stack`.

## 1. Load the Stack State

Load and follow the `gh-stack` skill before you run a `gh stack` command. Do not use flags from memory. Run `gh stack view --json`. If the repository has more than one remote and `remote.pushDefault` is not set, add `--remote <name>` to `gh stack sync`.

## 2. Sync

Run `gh stack sync --prune`. It fetches, gets changes to the stack from GitHub, fast-forwards the trunk, rebases the layers, pushes, refreshes the pull request state, and deletes local branches of merged pull requests.

Then do the step that agrees with the result:

- **The output contains `Sync aborted` (exit 0):** go to step 3.
- **Exit 3:** go to step 4.
- **Exit 0:** go to step 5.
- **Other exit codes:** use the exit code table in the `gh-stack` skill.

## 3. Fix a Divergence

`Sync aborted` means that the local stack and the stack on GitHub changed in different ways. Sync made no changes. Show both chains from the output. Then ask the user to choose one of these fixes:

- **Keep the GitHub stack:**

  ```bash
  gh stack unstack --local
  gh stack checkout <stack-number>
  ```

- **Keep the local stack:**

  ```bash
  gh stack unstack
  gh stack submit --auto
  ```

Pull requests and branches stay. Run the fix that the user chooses, then go back to step 2.

## 4. Fix a Conflict

When sync stops with a conflict, it restores each branch to its state before the rebase. No rebase is in progress, so `gh stack rebase --continue` does not apply.

Read `../rebase-stack/SKILL.md` (relative to this skill's directory) and run it in latest-trunk mode. Then go back to step 2.

## 5. Write the Descriptions

Read `../describe-stack/SKILL.md` and run it in fill mode for all pull requests.

## 6. Report

Run `gh stack view --json` and show a table: branch, PR URL, and PR state. List the branches that merged and the local branches that sync deleted.

## Required Behavior

- Do not choose a divergence fix for the user.
- Do not overwrite a pull request description that has real content.
