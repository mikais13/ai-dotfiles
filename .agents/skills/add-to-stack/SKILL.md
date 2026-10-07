---
name: add-to-stack
description: Start a gh-stack stack from the current branch chain, or add a branch on top of a stack, then open draft pull requests and write their descriptions.
disable-model-invocation: true
compatibility: Requires Git 2.36+, GitHub CLI with the gh-stack extension, and the gh-stack skill.
---

# Add to a Stack

This skill starts a stack when none exists, and adds a layer when a stack exists. The user does not need to say which case applies.

## 1. Load the Stack State

Load and follow the `gh-stack` skill before you run a `gh stack` command. Do not use flags from memory. Run `gh stack view --json`. If the repository has more than one remote and `remote.pushDefault` is not set, add `--remote <name>` to `gh stack submit`.

- If the command exits 2, there is no stack. Go to step 2.
- If it succeeds, go to step 3.

## 2. Start a Stack

1. Find the trunk. For each of `main`, `master`, `develop`, and `staging` that exists as `origin/<branch>`, run `git merge-base HEAD origin/<branch>`. The branch with the newest merge base is the trunk.
2. If `HEAD` is the trunk, ask the user for a name for the first layer. Use the naming conventions of the user or the repository. If there are none, use `<topic>/<concern>`. Run `gh stack init -b <trunk> <name>`. Stage and commit the changes as in items 3 and 4 of step 3.3, then go to step 4.
3. Find the branch chain. List the local branches (`git for-each-ref refs/heads --format='%(refname:short)'`). Keep each branch that is an ancestor of `HEAD` (`git merge-base --is-ancestor <branch> HEAD`) and that contains the trunk (`git merge-base --is-ancestor <trunk> <branch>`). Sort them from the bottom up by `git rev-list --count <trunk>..<branch>`.
4. Show the chain and the trunk to the user. Let the user correct them. Do not create a stack from a chain that the user did not confirm.
5. Run `gh stack init -b <trunk> <branch-1> … <branch-n>`. `init` adopts existing branches, so you do not need `gh stack add`.
6. If there are uncommitted changes, ask whether they belong to the top branch or to a new layer. Commit them on the top branch, or go to step 3.3.

Go to step 4.

## 3. Add a Layer

If there are no uncommitted changes and the user names no branch to add, but some layers have no `pr` entry, go to step 4 to open their pull requests.

1. The current branch must be the top layer: the last branch in the stack that is not merged. `gh stack add` fails on other branches. If the current branch is not the top layer, tell the user and stop. Do not move to another branch for the user.
2. **To add an existing branch:** make sure that it contains the top layer (`git merge-base --is-ancestor <top> <branch>`). If it does not, show `git log --oneline <top>..<branch>`, ask the user how to place the branch, and stop. Otherwise, run `gh stack add <branch>`.
3. **To add uncommitted changes:**
   1. If some changes belong to lower layers, recommend `/absorb-into-stack` for them first.
   2. Confirm the branch name with the user. Run `gh stack add <name>`. This command does not change the working tree, so the changes move to the new branch.
   3. Stage only the files that belong to this layer. If the changes are mixed, ask the user which files to stage.
   4. Run `git commit -m "<message>"`. Use the form `type(scope): summary`.
4. If there are no changes and no branch to add, ask the user what the new layer must contain.

## 4. Open the Pull Requests

Run `gh stack submit --auto`. It pushes each branch and opens a draft pull request for each branch that has none. Add `--open` only when the user asks for pull requests that are ready for review.

`submit` is not atomic. If the remote rejects a push, fix that branch and run the same command again. If it exits 9, stacked pull requests are not turned on for the repository. Tell the user.

## 5. Write the Descriptions

Read `../describe-stack/SKILL.md` (relative to this skill's directory) and run it in fill mode:

- For a new stack, fill all pull requests.
- For a new layer, fill only the pull request of the new layer.

## 6. Report

Run `gh stack view --json` and show a table: branch, PR URL, and PR state.

## Required Behavior

- Ask the user to confirm the branch chain and the trunk before you run `gh stack init`.
- Open draft pull requests unless the user asks for ready ones.
- Do not overwrite a pull request description that has real content.
- Stage files on purpose. Do not use `gh stack add -Am` to commit all changes.
