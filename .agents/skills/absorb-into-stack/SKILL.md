---
name: absorb-into-stack
description: Move uncommitted changes into the gh-stack layers that own them, commit them there, then realign and push the stack.
disable-model-invocation: true
compatibility: Requires Git 2.36+, GitHub CLI with the gh-stack extension, and the gh-stack skill.
---

# Absorb Changes Into a Stack

Use this skill when you made fixes on one layer, for example the top layer, but the fixes belong to lower layers. Each change goes to the layer that last changed those lines.

In this file, `rebase-stack` means `../rebase-stack/SKILL.md`, relative to this skill's directory. Read it when a step points to it.

## 1. Load the Stack State

Load and follow the `gh-stack` skill before you run a `gh stack` command. Do not use flags from memory. Run `gh stack view --json`. Use `git rev-parse <branch>` for the current tip of a branch, because the `head` field can be old.

- If there is no stack (exit 2), stop. Recommend `/add-to-stack`.
- If a rebase is in progress (`git rev-parse --git-path rebase-merge` exists), stop. Recommend `/rebase-stack` to complete it.
- If `git status --porcelain` shows no changes, stop.

Record the start branch.

## 2. Bring the Stack Up to Date

The changes must apply to the current layers, including commits that were added on GitHub.

1. Run `git stash push --include-untracked -m absorb-into-stack`.
2. Run steps 1 to 7 of `rebase-stack` in align mode. Do not push yet. If it reports that the stack is already aligned, continue.
3. Run `git switch <start-branch>`, then `git stash pop`.
4. If the pop causes conflicts, read both sides in each file (`git diff <path>`) and keep the intent of both. If the intent is not clear, ask the user. Then run `git add <path>` and `git stash drop`, because a pop with conflicts keeps the stash entry.

If you cannot complete this step, run `git switch <start-branch>` and tell the user that the changes are in the stash entry `absorb-into-stack`.

## 3. Map Each Change to a Layer

Get the changes without context lines, so that blame sees only the changed lines:

```bash
git diff -U0 HEAD                          # staged and unstaged changes
git ls-files --others --exclude-standard   # new files
```

For each hunk `@@ -<start>,<count> …`. When Git leaves out `,<count>`, the count is 1.

1. Find the commits that last changed the old lines:
   - If `<count>` is more than 0: `git blame -L <start>,<start + count - 1> HEAD -- <path>`
   - If `<count>` is 0, the hunk only adds lines after line `<start>`. Blame line `<start>` and line `<start + 1>`.
2. The owner of a commit is the lowest layer that contains it (`git merge-base --is-ancestor <commit> <branch>`). If no layer contains the commit, the lines came from the trunk.
3. If the commits have different owners, use the highest owner. Only that layer contains all the lines.

Then apply these rules:

- If all hunks of a file have the same owner, move the whole file to that layer.
- If the lines came from the trunk, or the file is new, ask the user. Suggest the layer that changes related files.
- If a change uses code that only a higher layer adds, move the change to that higher layer. A lower layer cannot use code that it does not contain.
- Each target layer must be the start branch or a layer below it. To put a change in a layer above the start branch, the user must run this skill from that layer.

## 4. Confirm the Plan

Show a table: file or hunk, target layer, and the reason. Also show one commit message for each target layer, in the form `type(scope): summary`. Wait for the user's confirmation. The user can move changes or edit the messages.

## 5. Save the Changes

```bash
dir=$(git rev-parse --path-format=absolute --git-path absorb-into-stack)
mkdir -p "$dir"
git add -A
git write-tree > "$dir/expected-tree"
git diff --cached --binary -U0 --no-color --no-ext-diff --src-prefix=a/ --dst-prefix=b/ HEAD -- <paths> > "$dir/<layer>.patch"
git stash push -m absorb-into-stack
```

- Write one patch for each target layer. In the file name, replace each `/` in the branch name with `-`.
- The patches have no context lines (`-U0`). Context lines can come from a higher layer, and then the patch does not apply to the lower layer.
- If the hunks of one file go to different layers, write the patch for the whole file. Then, in each layer's patch, delete the hunks that go to other layers. Keep the file headers.
- Shell variables do not stay between commands. Run `git rev-parse` again, or use the absolute path that it printed.

## 6. Commit in Each Layer

For each target layer, from the bottom layer to the top layer:

1. Run `git switch <layer>`. If another worktree has the layer checked out, run the commands in that worktree with `git -C <path>`.
2. Run `git apply --index --unidiff-zero "$dir/<layer>.patch"`. This stages the change.
3. If the patch does not apply, Git changes nothing. Run `git apply --3way --unidiff-zero "$dir/<layer>.patch"`. If this causes conflicts, read both sides in each file (`git diff <path>`) and keep the intent of both. If the intent is not clear, ask the user. Then run `git add <path>`.
4. Run `git commit -m "<message>"`.

## 7. Realign the Stack

Run steps 1, 2, and 4 to 7 of `rebase-stack` in align mode. Skip its step 3: step 2 of this skill already got the commits from GitHub, and the layers that step 2 realigned are not pushed yet. Do not push yet. If it reports that the stack is already aligned, continue with step 8 of this skill.

A fix next to lines that a higher layer adds can cause a rebase conflict in that higher layer. This is normal. Resolve it with step 6 of `rebase-stack`.

## 8. Verify

1. Run `git switch <start-branch>`.
2. `git diff $(cat "$dir/expected-tree") HEAD` must be empty. If it is not empty, show the difference to the user and stop. Do not push, and do not drop the stash.
3. Find the stash entry from step 5 with `git stash list --format='%gd %gs'`, and drop it with `git stash drop <ref>`. Then remove `$dir`.

## 9. Push and Report

Run step 8 of `rebase-stack` to push. Then run `gh stack view --json` and show a table: layer, new commit (the SHA after the rebase), files, and PR URL. Show only the layers that got a commit. If a layer has no `pr` entry, write "No PR" and recommend `/add-to-stack`.

## Required Behavior

- Make a new commit in each layer, so that reviewers can see the change. Amend or squash only when the user asks.
- Do not drop the stash from step 5 until the check in step 8 passes.
- If you cannot complete the procedure, run `git switch <start-branch>`. Tell the user which layers have new commits, and that the original changes are in the stash entry `absorb-into-stack`.
- Do not move the trunk. Use align mode.
