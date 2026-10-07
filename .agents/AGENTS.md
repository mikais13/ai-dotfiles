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
- Use `rtk proxy <command>` or the original command when you need the exact, complete output.
- `rtk gain` shows the token savings. `rtk discover` finds commands that RTK can reduce.
