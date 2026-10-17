#!/usr/bin/env bash

# WorktreeCreate hook: put Claude worktrees in the central layout,
# ~/localdocs/worktrees/<repo>/<name>, and copy local files into them.
# Claude Code reads the last stdout line as the worktree path, so all other
# output goes to stderr.
set -euo pipefail

input=$(cat)
name=$(jq -r .name <<<"$input")
cwd=$(jq -r .cwd <<<"$input")

main=$(git -C "$cwd" worktree list --porcelain | awk 'NR == 1 { print substr($0, 10) }')
dst=$HOME/localdocs/worktrees/$(basename "$main")/${name//\//-}

if [[ ! -d $dst ]]; then
    {
        git -C "$main" fetch -q origin || true
        if git -C "$main" rev-parse -q --verify "refs/heads/$name" >/dev/null; then
            git -C "$main" worktree add "$dst" "$name"
        else
            base=origin/HEAD
            git -C "$main" rev-parse -q --verify "$base" >/dev/null || base=HEAD
            git -C "$main" worktree add --no-track -b "$name" "$dst" "$base"
        fi
    } >&2
    "$HOME/.local/bin/worktree-setup" "$main" "$dst" --no-install
fi

printf '%s\n' "$dst"
