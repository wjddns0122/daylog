---
trigger: always_on
---

---

description: "Quality bar: golden tests, widget/unit tests, CI-ready patterns"
globs: ["lib/**/*.dart", "test/**", ".github/workflows/**"]
alwaysApply: true

---

# Quality & QA

## Testing targets

- Golden tests for key screens (Splash, Login, Home Feed list/grid, Developing, Result)
- Unit tests for:
  - ViewModels state transitions
  - fallback template selection deterministic behavior
  - countdown math using developAtServer
- Repository tests with fakes/mocks.

## CI hygiene

- No flaky timers: inject clock/time provider.
- Avoid real Firebase in unit tests; use emulators or mocks.

## Code health

- Keep functions small, single responsibility.
- Prefer composition over god classes.
