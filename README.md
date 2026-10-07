# AI dotfiles

My global configuration for AI coding agents. Claude Code is the main agent. Codex and OpenCode use the same shared instructions and skills. The configuration is for development work only.

## Layout

The repository root mirrors `$HOME`. GNU Stow links the contents into place.

| Path | Contents |
| --- | --- |
| `.agents/AGENTS.md` | Shared global instructions. It has no `@` imports, because Codex and OpenCode do not expand them. |
| `.agents/skills/` | The only copy of each shared skill. Codex and OpenCode read this directory. |
| `.claude/` | Claude Code: `CLAUDE.md` (imports the shared instructions), `settings.json`, the status line, and the `pr-creator` agent. |
| `.claude/skills/` | Relative links to `../../.agents/skills/<name>`. Claude Code reads only `~/.claude/skills`. |
| `.codex/` | Codex: a link to the shared `AGENTS.md`, `hooks.json`, and `config.base.toml`. |
| `.config/opencode/` | OpenCode: `opencode.json` and a link to the shared `AGENTS.md`. |

T3 Code uses the configuration of each agent above. It needs no files here.

## Shared or Claude-only

- Put instructions and skills that all agents can use in `.agents`.
- Put Claude-only content in `.claude`: settings, hooks, agents, and skills that need Claude-only features, such as `` !`command` `` or `$ARGUMENTS`.
- A shared skill can contain Claude-only frontmatter keys, such as `context: fork` in `create-pr`. Codex and OpenCode ignore unknown keys.

## Install

Requirements: Git, GNU Stow, Node.js (status line), `jq` (`.env` guard hook), and [RTK](https://github.com/rtk-ai/rtk).

```sh
git clone git@github.com:mikais13/ai-dotfiles.git ~/ai-dotfiles
cd ~/ai-dotfiles
stow --simulate --verbose .   # Check for conflicts.
stow .
cp -n .codex/config.base.toml ~/.codex/config.toml   # First installation only.
```

Stow does not replace existing files. If it reports a conflict, move that file away and run `stow .` again.

After installation:

1. Sign in to each agent.
2. In Claude Code, install the plugins in `settings.json` with `/plugin`.
3. In Codex, trust the hooks with `/hooks`.
4. Install [Plannotator](https://github.com/backnotprop/plannotator). Its installer adds the `plannotator` core skills and the OpenCode commands.
5. For the `typescript-lsp` plugin in Claude Code and Codex, run `npm install -g typescript-language-server typescript`. OpenCode has a built-in TypeScript server.

## Add a skill

For your own skill:

```sh
mkdir .agents/skills/<name>        # Add SKILL.md. Its name must equal <name>.
ln -s ../../.agents/skills/<name> .claude/skills/<name>
```

For a third-party skill, run `npx skills add <source> -g`. Then make sure that `.claude/skills/<name>` is a relative link to `../../.agents/skills/<name>`. Commit the skill, the link, and `.agents/.skill-lock.json`.

To update third-party skills, run `npx skills update`.

## Local data

- Runtime data stays in `~/.claude`, `~/.codex`, and `~/.config/opencode`. It is not in this repository.
- `~/.codex/config.toml` is local, because Codex writes project trust, hook trust, and machine paths to it. Copy portable changes to `.codex/config.base.toml` manually.
- `.gitignore` excludes the skills that Claude Code syncs from claude.ai (`skills/synced/`) and the Plannotator core skills.

## Known quirks

- In this repository, each agent also reads `.claude/`, `.codex/`, and `.agents/` as project configuration. The duplicates do no harm, because Claude loads a linked target only once. Codex loads project hooks only after you trust the project.
- Edit files through their paths in `~/ai-dotfiles`. The Claude Code Edit and Write tools do not write through symlinks.
- `rtk init` adds an `RTK.md` file and an `@RTK.md` line. The RTK notes are in `.agents/AGENTS.md`, so remove these additions.
- Do not edit the Codex custom instructions in the desktop app. The app can replace the `AGENTS.md` link with a file.
- Codex keeps hook trust per machine. After you change `hooks.json`, trust the hooks again with `/hooks`.
- OpenCode reads both `~/.claude/skills` and `~/.agents/skills`, so it logs a duplicate-name warning for each shared skill. To stop this, set `OPENCODE_DISABLE_CLAUDE_CODE_SKILLS=1`.
