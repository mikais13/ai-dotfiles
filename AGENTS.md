# Guide for Agents in This Repository

This repository holds the global AI agent configuration of the user. GNU Stow links its contents into `$HOME`. A change here changes the live setup of each agent.

- Read `README.md` before you make changes.
- Put shared content in `.agents`. Put Claude-only content in `.claude`. Keep the Codex and OpenCode layers small.
- Keep `.agents/AGENTS.md` self-contained. Do not use `@` imports in it.
- Each shared skill needs a relative link from `.claude/skills/<name>` to `../../.agents/skills/<name>`.
- The `name` of a skill must equal its directory name. Use lowercase letters, digits, and hyphens.
- Do not track runtime data, credentials, machine paths, or files that a tool generates.
- Edit files through their paths in this repository, not through the links in `$HOME`.
- Do not add a file at the repository root unless `.stow-local-ignore` excludes it. For example, a `~/AGENTS.md` link would load in every project below `$HOME`.
- Make one commit for each concern. Use `type(scope): summary` commit messages.
- Before you commit, make sure that `stow --simulate --verbose .` reports no conflicts and that each JSON and TOML file parses.
