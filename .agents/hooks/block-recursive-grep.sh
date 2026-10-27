#!/usr/bin/env bash

# PreToolUse hook for Bash: deny recursive grep in favour of rg.
cmd=$(jq -r '.tool_input.command // empty')

# Ignore quoted text and `git grep`.
unquoted=$(sed -E "s/'[^']*'//g; s/\"([^\"\\\\]|\\\\.)*\"//g; s/git[[:space:]]+grep//g" <<<"$cmd")

# grep with -r, -R, --recursive, --include, or --exclude-dir.
if grep -qE '(^|[;&|(`[:space:]])e?grep[[:space:]]([^;&|]*[[:space:]])?(-[[:alnum:]]*[rR][[:alnum:]]*|--recursive|--include|--exclude-dir)([=[:space:]]|$)' <<<"$unquoted"; then
    jq -n '{hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "Do not use recursive grep. Use rg: `rg -n pattern path`. Filter by type with `-t ts` or a quoted glob (`-g '\''*.tsx'\''`). Add `--no-ignore` to search gitignored paths such as node_modules. Plain grep in a pipe is fine."
    }}'
fi
