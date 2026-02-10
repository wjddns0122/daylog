---
trigger: always_on
---

---

description: "Security/privacy rules: encryption, Firestore rules principles, least privilege"
globs: ["firestore.rules", "storage.rules", "functions/**", "lib/**/*.dart"]
alwaysApply: true

---

# Security & Privacy

## Musts

- Photos are stored locally encrypted before upload.
- Until ready/fallback, data must not leak cross-user.
- Firestore rules must enforce:
  - users can read/write only their own profile (with limited public fields if feed requires)
  - shots: author-only read/write for journaling fields; public read only if explicitly a social feed requirement exists
  - day locks: author-only read; server-only write (via admin SDK)

## Storage rules

- enforce path: shots/{uid}/{localDayKey}/{shotId}.webp
- only owner can upload to their path
- enforce contentType image/webp
- enforce max size

## Cloud Functions

- verify auth token on every HTTPS endpoint
- validate inputs (timezone)
- prevent replay/double-commit using tx + lock

## Logging

- avoid logging PII/photo URLs in plaintext logs
- structured logs only, redact tokens
  .cursor/rules/70_quality_testing_ci.mdc

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
