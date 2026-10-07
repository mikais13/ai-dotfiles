---
name: create-pr
description: Create a well-formatted GitHub pull request for the current branch. Use when the user asks to create, open, or draft a pull request.
compatibility: Requires git, GitHub CLI, network access, and the pr-description skill.
# Claude Code only. Other harnesses ignore these keys.
context: fork
agent: pr-creator
background: false
---

# Create a Pull Request

## 1. Inspect the Branch

Run independent read-only checks in parallel when possible:

- `git branch --show-current`
- `git remote show origin`
- `git status`

Stop if the current branch is the repository's default branch.

For each remote branch that exists in `main`, `master`, `develop`, and `staging`, find its merge base with `HEAD`. Recommend the branch with the newest merge base.

## 2. Confirm User Choices

Ask the user to select the base branch and one title option:

- generate a semantic title from the changes; or
- use a title that the user supplies.

Use the selected base branch for every later comparison and for pull request creation.

## 3. Load the Description Rules

Load and follow the `pr-description` skill. Give it the selected base branch. Do not write the description from memory.

## 4. Analyze the Changes

Run:

```bash
git log <base>...HEAD --oneline
git diff <base>...HEAD --stat
git diff <base>...HEAD
```

Read key files if the diff is too large to understand from one command.

## 5. Create the Pull Request

If the user asked for a generated title, use `type(scope): description`. Use an imperative, lowercase description. Types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `ci`, `build`.

Warn about uncommitted changes, but create the pull request from committed changes. Push an unpublished branch with:

```bash
git push -u origin HEAD
```

Create a draft pull request unless the user explicitly asks for a ready pull request:

```bash
gh pr create --draft --base <base> --title <title> --body-file <body-file>
```

Return the pull request URL.

## Required Behavior

- Ask the user to confirm the base branch and title method.
- Use the same base branch for analysis, description generation, and creation.
- Include a specific "How to test this change" section.
- Use backticks for code references.
- Do not add a co-author line unless the user requests it.
