#!/usr/bin/env bash

# WorktreeRemove hook: remove a worktree that worktree-create.sh made, with
# its tmux session and zoxide entry. git refuses to remove a dirty worktree,
# so uncommitted work stays on disk and Claude reports the failure.
set -euo pipefail

dir=$(jq -r .worktree_path)

# Run git from the main checkout, not from the worktree being removed.
common=$(git -C "$dir" rev-parse --path-format=absolute --git-common-dir)
git -C "$(dirname "$common")" worktree remove "$dir"
zoxide remove "$dir" 2>/dev/null || true
tmux list-sessions -F $'#{session_id}\t#{session_path}' 2>/dev/null |
    awk -F'\t' -v p="$dir" '$2 == p { print $1 }' |
    while IFS= read -r id; do tmux kill-session -t "$id"; done
