---
name: describe-stack
description: Write missing pull request titles and descriptions for a gh-stack stack, or rewrite the ones that the user names.
disable-model-invocation: true
compatibility: Requires Git 2.36+, GitHub CLI with the gh-stack extension, and the gh-stack and pr-description skills.
---

# Describe a Stack

Other stack skills read this file and run fill mode. A caller can limit fill mode to some pull requests.

## 1. Load the Stack State

Load and follow the `gh-stack` skill before you run a `gh stack` command. Do not use flags from memory. Run `gh stack view --json`.

Skip a branch that has no `pr` entry. Tell the user to open its pull request with `/add-to-stack` or `gh stack submit --auto`.

## 2. Choose the Mode

- **Fill mode:** the default. Write a description only for a pull request that has a stub body. Do not change a pull request that already has real content.
- **Rewrite mode:** when the user names pull requests or branches, rewrite those pull requests, even if they have content. Use fill mode for the other pull requests in the stack.

## 3. Find the Gaps

For each pull request, run:

```bash
gh pr view <number> --json body,title,baseRefName,headRefName
```

A body is a stub when one of these is true:

- It is empty, or it contains only white space.
- It is the same text as the body of a commit on the branch (`git log --format=%b <baseRefName>..<headRefName>`). `gh stack submit --auto` writes this.

In fill mode, skip each pull request that does not have a stub body.

## 4. Write the Description

For each pull request to write:

1. Use `baseRefName` as the base. Do not use the `base` field from `gh stack view --json`, because it is a commit SHA, not a branch name.
2. Load the `pr-description` skill. Give it the base branch `<baseRefName>`.
3. Get the changes:

   ```bash
   git log <baseRefName>...<headRefName> --oneline
   git diff <baseRefName>...<headRefName>
   ```

4. Write the description. Write it to a temporary file without the fenced code block that `pr-description` uses for display.
5. Keep the current title if it has the form `type(scope): description` and the pull request is not in rewrite mode. Otherwise, write a new title in that form. Use an imperative, lowercase description. Types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `ci`, `build`.
6. Apply them:

   ```bash
   gh pr edit <number> --title "<title>" --body-file <file>
   ```

## 5. Report

Show a table with one row for each pull request: number, title, and the result (written, rewritten, or skipped).

## Required Behavior

- Overwrite a description that has real content only in rewrite mode, and only for the pull requests that the user names.
- Use the same `baseRefName` for the diff and for `pr-description`.
- Do not add a co-author line.
