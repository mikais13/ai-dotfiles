#!/usr/bin/env bash

# PreToolUse hook for Bash: deny commands that use a .env file as a path.
cmd=$(jq -r '.tool_input.command // empty')

# .env, .env.local, or .env* after a space, slash, quote, =, or redirect.
# Example, sample, and template files pass.
paths=$(perl -ne 'print "$1\n" while /(?:^|[\s\/=<>"\x27])(\.env(?:\.[\w-]+|\*)?)(?=[\s;|&)<>"\x27]|$)/g' <<<"$cmd" |
    grep -vE '^\.env\.(example|sample|template)$')

if [[ -n $paths ]]; then
    jq -n '{hookSpecificOutput: {
        hookEventName: "PreToolUse",
        permissionDecision: "deny",
        permissionDecisionReason: "Blocked: command references a .env file"
    }}'
fi
