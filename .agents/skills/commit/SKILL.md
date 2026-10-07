---
name: commit
description: How to commit changes in Mikai's repos. Use whenever the user asks to commit, make commits, "commit this", "commit the changes", or wrap up a feature, even if they do not say how to split the work.
---

# Commit

## Decide how many commits

Read `git status` and `git diff` (staged and unstaged) first.

Use one commit by default. Most work, including most features, fits in one commit.

Add a commit only when it helps a reviewer follow the story of the change. Each commit is one high-level part of the work, for example the data model, API, and UI of a feature. Do not make one commit for each file, function, or small step.

- Keep tests, docs, and config with the change they support.
- Keep a pure move or rename separate from content edits, so that the diff stays readable.
- Put an unrelated fix that you found during the work in its own commit.

If a reviewer would lose nothing when two commits merge, merge them. Each commit should build and make sense alone.

## Message format

Use Conventional Commits: `type(scope): summary`.

- Types: `feat`, `fix`, `refactor`, `chore`, `docs`, `test`, `perf`, `style`, `build`, `ci`.
- Summary: imperative, lowercase, no period, 72 characters or less.
- Add a body only when the reason for the change is not clear from the summary.
- Follow the repo's own conventions if `git log` shows different ones.

## Do not

- Do not push unless the user asks.
- Do not commit secrets, build output, or unrelated files. If unrelated changes are in the tree, ask before you include them.
