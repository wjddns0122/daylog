---
trigger: always_on
---

---

description: "Flutter MVVM + Riverpod + Freezed conventions for Daylog"
globs: ["lib/**/*.dart"]
alwaysApply: true

---

# Flutter Architecture Rules (MVVM)

## Folder conventions (recommended)

lib/
app/ (app entry, router, theme)
core/ (constants, utils, error, networking)
features/
auth/
data/ (datasources, repositories)
domain/ (models/entities if needed)
presentation/
screens/
widgets/
viewmodels/
shot/
feed/
archive/
share/
firebase/ (firebase init, refs, helpers)
l10n/

## Riverpod patterns

- Prefer `Notifier`/`AsyncNotifier` for async state.
- ViewModel owns state + commands.
- UI reads provider state and dispatches actions only.
- Never call Firebase directly in Widgets; use repository/provider layers.

## Freezed models

- All Firestore/HTTP models are immutable `@freezed`.
- Provide:
  - fromJson/toJson
  - optional fields for server timestamps
  - safe defaults (e.g., empty list for likes)

## Error handling

- Standardize error types (e.g., AppError).
- View state includes:
  - loading
  - data
  - error (message + retry action)
- No silent failures.

## Performance

- Use const widgets and `select`/`listen` properly.
- Avoid rebuilding whole screens on small state changes.
