# Global Coding Standards

1. **YAGNI**: Don't build it until you need it
2. **DRY**: Extract patterns after second duplication, not before
3. **Fail Fast**: Explicit errors beat silent failures
4. **Simple First**: Write the obvious solution, optimize only if needed or instructed - *KISS (Keep it simple stupid)*
5. **Delete Aggressively**: Less code = fewer bugs
6. **Semantic Naming**: Prefer to name variables, parameters, and API endpoints with verbose, self-documenting names that optimise for comprehension by both humans and LLMs, not brevity (e.g. `wait_until_obs_is_saved=true` vs `wait=true`)

# Writing Guidelines

Write in ASD-STE100 Simplified Technical English. Also follow these writing principles:

- Simplicity
- Brevity
- Clarity
- Humanity

# RTK

RTK (`rtk`) is a command proxy. It reduces command output when the full output is not necessary.

- Some clients use a hook that sends shell commands through RTK automatically.
- If your client has no hook, use `rtk <command>` when reduced output is sufficient.
- Use `rtk bypass <command>` or the original command when you need the exact, complete output.
- `rtk gain` shows the token savings. `rtk discover` finds commands that RTK can reduce.
