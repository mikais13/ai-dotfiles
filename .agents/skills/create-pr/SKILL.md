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

## 2. Choose the Base Branch

If the user names a base branch, use it.

Otherwise, select the base branch from the evidence:

- the branch that this branch was created from, if `git reflog` or a stack tool such as `gh stack` shows it;
- for each remote branch that exists in `main`, `master`, `develop`, and `staging`, the merge base with `HEAD`; the newest merge base is usually the parent;
- an open pull request whose head branch is the parent of this branch, for stacked work.

If one branch is clearly correct, use it and do not ask. If two or more branches are possible, use the question tool of the harness (`AskUserQuestion` in Claude Code). Give two to four candidates. Put the recommended branch first, and give the reason for each candidate.

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

Select the title. Do not ask the user about the title.

1. If the user supplies a title, use it.
2. If the branch has one commit, use the subject of that commit.
3. Otherwise, generate a title in the commit format of the repository. Find the format in the branch commits and in `git log <base> --oneline -20`. This is usually Conventional Commits: `type(scope): description`, with an imperative, lowercase description. Types: `feat`, `fix`, `refactor`, `docs`, `style`, `test`, `chore`, `perf`, `ci`, `build`.

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

- Ask about the base branch only when it is not clear.
- Do not ask about the title. Use the title rules in step 5.
- Use the same base branch for analysis, description generation, and creation.
- Include a specific "How to test this change" section.
- Use backticks for code references.
- Do not add a co-author line unless the user requests it.
