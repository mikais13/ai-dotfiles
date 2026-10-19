#!/usr/bin/env bash
# rtk-hook-version: 4
# rtk reads the line above. Without it, rtk takes this file for its old hook
# script of the same name and warns that the hook is outdated.

# PreToolUse hook for Bash: run rtk's rewrite, except for git commands in a
# linked worktree. Claude Code's worktree guard refuses `rtk git ...` in a
# worktree-isolated session, so git must run there as plain git.
input=$(cat)
cwd=$(jq -r '.cwd // empty' <<<"$input")
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")

if grep -qE '(^|[^[:alnum:]_-])git([[:space:]]|$)' <<<"$cmd"; then
    dir=$(git -C "$cwd" rev-parse --path-format=absolute --git-dir 2>/dev/null)
    common=$(git -C "$cwd" rev-parse --path-format=absolute --git-common-dir 2>/dev/null)
    [[ -n $dir && $dir != "$common" ]] && exit 0
fi

rtk hook claude <<<"$input"
