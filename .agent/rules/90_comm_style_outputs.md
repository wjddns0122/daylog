---
trigger: always_on
---

---

description: "Communication/output format: how to present plans, diffs, and next questions"
globs: ["**/*"]
alwaysApply: true

---

# Output Format Contract

## When user asks to implement something

Return:

1. Plan (scope + steps)
2. Files to change (path list)
3. Code blocks per file
4. Manual verification checklist

## Preemptive follow-up questions (only when blocking)

Ask only what is truly blocking:

- exact Figma node/spec values
- which auth methods enabled first (google/kakao/email)
- whether feed is public or friends-only (impacts rules)
- final routing decisions (go_router vs Navigator)

If not blocking, proceed with best defaults but label them as TODO.
