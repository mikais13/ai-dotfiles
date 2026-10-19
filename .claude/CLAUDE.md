@~/.agents/AGENTS.md

# Claude Code

- A `PreToolUse` hook sends Bash commands through `rtk hook claude`. For example, `git status` runs as `rtk git status`. Use `rtk proxy <command>` when you need raw output.
- In a git worktree, the hook does not rewrite git commands. Run git there as plain `git`, never as `rtk git` or `rtk proxy git`, because the worktree guard refuses them.
