#!/usr/bin/env bash

# PreToolUse hook for Bash: deny `git worktree add`. A raw add skips the
# WorktreeCreate hook, so the worktree lands outside the central layout and
# gets no env files. EnterWorktree runs that hook and moves the session in.
cmd=$(jq -r '.tool_input.command // empty')

# Only git options (and their values, such as -C <dir>) may come between
# `git` and `worktree`, so commit messages that mention it still pass.
if grep -qE '(^|[^[:alnum:]_-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+worktree[[:space:]]+add([[:space:]]|$)' <<<"$cmd"; then
    jq -n '{hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "Do not run git worktree add. Use the EnterWorktree tool instead, with the branch name as the worktree name. A hook creates the worktree in ~/localdocs/worktrees/<repo>/<name>, copies the env files, and moves this session into it. Run pnpm install there if the task needs dependencies."
    }}'
fi
