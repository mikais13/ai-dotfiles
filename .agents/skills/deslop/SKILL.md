---
name: deslop
description: Find and remove AI-generated patterns in code changes in any language, such as obvious or long comments, gratuitous defensive checks, fallbacks for required values, type escape hatches, verbose logging, leftover debug code, and over-engineering. Use when the user asks to deslop, deslopify, remove slop, clean up AI-written code, or review a branch, diff, PR, or stacked branch for code that does not match the codebase. Use it also when the user says that agent-written code "reads like AI" or is "too verbose".
---

# Deslop

Find and remove AI-generated patterns in code changes. The reference is the surrounding codebase, not a general style guide. A line is slop when a person who knows this codebase would not write it.

## Scope

- Change only the lines that the diff adds or changes. Do not clean up old code.
- If the arguments name a base branch, a commit range, or paths, use them.
- Report first. List the findings and wait for the user's approval before you edit. The user can approve all, some, or none. If the user already said "fix it" or "apply", edit without the wait.

### Find the base

Do not assume `main`.

1. If the user or the caller names a base, use it.
2. If `gh stack view --json` shows that the branch is in a stack, the base is the branch below it. Also diff the branches above it. Do not change code that an upstack branch already changes or deletes, because that duplicates work and causes rebase conflicts.
3. Otherwise, use the default branch of the remote: `git remote show origin | sed -n 's/.*HEAD branch: //p'`.
4. If the base is still not clear, ask.

Get the diff with `git diff <base>...HEAD`. Add `git diff HEAD` for uncommitted changes.

## What to look for

### Comments

Remove comments that:

- say what the next line does, or repeat a name
- explain _what_ and not _why_
- add doc blocks to trivial functions when the file does not use doc blocks
- tell the history of the change ("Added X", "Now uses Y"). This belongs in the commit or PR.
- do not agree with the code

Shorten a comment that gives a real reason but is longer than two lines. Keep only the key reason. Long reasoning goes in the PR description. Match the comment density of the file: if nearby code has no comments, one line is the maximum.

Keep a comment that repeats a convention from sibling files, such as the same "why" comment at each similar call site. If you remove it from one file, the files become inconsistent.

```python
# ❌ Remove: says what the code does
# Check if the user is valid
if is_valid_user(user):

# ❌ Shorten: five lines for one reason
# We need to check the token expiry here before we validate.
# This is important because expired tokens can cause the
# validator to throw errors that are hard to understand.
# By checking first, we make sure that the error messages
# stay clear for the caller.
if is_expired(token):
    return None

# ✅ Keep: one line, the reason only
# Expired tokens make the validator throw unclear errors.
if is_expired(token):
    return None
```

### Defensive code

Remove defensive code that the codebase does not use, especially:

- null checks on values that callers or types already guarantee
- runtime type checks on typed parameters
- try/catch that swallows errors, or catches only to log and throw again, in trusted paths
- fallback defaults for values that the type or schema marks as required. They make the type look weaker than it is.

Keep validation at system boundaries: HTTP handlers, CLI input, file parsing, environment variables, and third-party responses.

```go
// ❌ Remove if callers already validate
func processOrder(order *Order) error {
    if order == nil {
        return errors.New("order is required")
    }
    // ...
}

// ✅ Keep: validation at a system boundary
func handleRequest(w http.ResponseWriter, r *http.Request) {
    if r.Body == nil {
        http.Error(w, "missing body", http.StatusBadRequest)
        return
    }
    // ...
}
```

```typescript
// ❌ Remove: `name` is required in the schema, so the fallback never runs
const label = sponsor.name ?? "Unknown sponsor";
```

### Type escape hatches

AI often silences the type checker instead of fixing the types. Common forms:

- casts to a top type: `as any`, `Any`, `interface{}`, `Object`, `dynamic`
- suppressions: `@ts-ignore`, `# type: ignore`, `//nolint`, `@SuppressWarnings`, `#[allow(...)]`, `eslint-disable`, `biome-ignore`
- forced unwraps that hide a real case: `!`, `.unwrap()`, `!!`
- unchecked casts where a guard or pattern match works

Fix the type. Prefer `unknown` (or the language's equivalent) with narrowing, a type guard, a generic, or the correct type. With `unknown`, the compiler makes the checks necessary, so a later refactor cannot remove them as "redundant". Keep a suppression only when it is necessary and follows the codebase convention, for example a `biome-ignore` with a reason.

```typescript
// ❌ Bad
const result = (data as any).value;

// ✅ Good
if (hasValue(data)) {
  const result = data.value;
}
```

### Over-engineering

Remove abstractions that the diff adds and nothing needs:

- wrappers that only call another function
- interfaces, traits, or abstract classes with one implementation
- type parameters that are not reused
- options objects for one call site
- compatibility shims, re-exports, or flags for code that has no other users
- flexibility that nobody asked for

Do not delete a generic helper, or the env or CI config that it needs, only because it has no callers now. Later work can use it. Inline a one-use helper only when the diff adds it and the code becomes clearer. If you are not sure, ask. An explicit request from the user overrides this rule.

```python
# ❌ Remove: wrapper that adds nothing
def get_item_count(items):
    return len(items)

# ❌ Remove: options object for one call site
@dataclass
class ProcessingOptions:
    validate: bool

def process(data, options: ProcessingOptions): ...
# Only call: process(data, ProcessingOptions(validate=True))
```

### Logging

Match the logging level and mechanism of the codebase. Remove step-by-step progress logs.

```javascript
// ❌ Remove if the file does not log at this level
console.log("Processing started");
console.log("Input validated successfully");

// ✅ Keep: matches the existing error logging
logger.error(`Failed to process order ${orderId}: ${err.message}`);
```

### Leftovers

- debug prints, commented-out code, unused imports and variables
- placeholder `TODO`s that the agent wrote
- notes or summary files that the agent added and the user did not ask for. Report these. Do not delete them without approval.

### Style

Compare with the unchanged parts of the same file and with neighbor files:

- naming conventions
- import style
- error handling (exceptions, return values, or result types)
- formatting that the formatter does not enforce
- idioms of the language, for example index loops where the codebase uses iterators

## Process

1. Find the base and get the diff.
2. Read each changed file in full, and one or two neighbor files.
3. Ask for each changed hunk: "What makes this look AI-written?"
4. Report the findings and wait for approval.
5. Make the approved fixes only. Do not change the behavior of correct code. If a removal can change behavior, keep the code and report it.
6. Verify. Use the project's own scripts for type checks, lint, and tests (for example, `package.json` scripts or a `Makefile`), not raw tool commands such as `npx tsc`. Report failures.
7. Do not commit unless the user asks. If they ask, make one commit on the current branch with a `type(scope): summary` message and no agent attribution.
8. Summarize.

## Output

Write in Simplified Technical English.

Findings report (step 4): group by file. Give each finding the line, the pattern, and the fix. Then list what you keep on purpose.

```
src/orders.ts
- 12: `as any` cast on `data`. Fix: type it as `unknown` and narrow.
- 30-34: five-line comment. Fix: cut to "Expired tokens make the validator throw unclear errors."
- 51: fallback for required `name`. Fix: remove.

Kept on purpose
- src/lib/fetch.ts: `serviceFetch` has no callers now, but it is a generic helper.
```

Final summary (step 8): 1–3 sentences that name the files. Then, one line each, list what needs a decision.

```
Removed 3 redundant null checks in order_processor.go, because callers validate the order.
Cut 8 obvious comments and removed 2 try/except blocks that hid errors.
```
