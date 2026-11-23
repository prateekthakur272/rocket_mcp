# Contributing to Rocket MCP

Thanks for helping. This page covers how to set up, how the code is organised, what a change should look like, and how to send it.

## Ways to help

- **Report a bug.** Press the **bug icon** in the status bar: it opens a new GitHub issue with a template and your Rocket MCP version and operating system filled in (nothing else is added). Say what happened, what you expected and the steps to reproduce. The server you were using, and a copy of the Traffic Inspector entry, help a lot.
- **Suggest a feature** by describing the problem before the solution.
- **Improve the docs.** They live in `docs/`.
- **Send a pull request** for a fix or a feature.

## Setting up

1. Install [Flutter](https://docs.flutter.dev/get-started/install) (stable) with the desktop toolchain for your system.
2. Fork and clone the repository, then run `flutter pub get`.
3. Run the app: `flutter run -d macos` (or `-d windows`, `-d linux`).
4. Run the checks: `flutter analyze` and `flutter test`.

## Finding your way around

Read [project-structure.md](project-structure.md), then [ARCHITECTURE.md](ARCHITECTURE.md), then the [engineering guidelines](guidelines.md). The short version:

- `features/<name>/` for a part of the app a user can point at, `components/` for reusable widgets, `utils/` for small helpers and constants, `core/` for logic with no UI, `app/` for state.
- **`core/` never imports `app/`, `features/`, `components/`, `theme/` or `platform/`.** It must be testable without a UI.
- A reusable widget goes in `components/`; a helper in `utils/`. Prefer reusing what is there over writing a second copy.

## Conventions

**Dart**

- `dart format lib test`, and keep `flutter analyze` clean.
- One responsibility per file. A file that passes a few hundred lines, or mixes two jobs, gets split by responsibility.
- Private (`_name`) unless another file needs it. Comments say *why*; public members that are not obvious get a one-line `///`.
- Never swallow a failure: use `Log.warning` / `Log.error`. Never log secrets, environment values, headers, or tool arguments and results.

**UI**

- Use the palette (`context.pal`) and the shared components (`T`, `Btn`, `IconBtn`, `IconBtnGroup`, `Field`, `ModalBox`, `EmptyState`, `ItemTile`, `HeaderBar`, `ResizablePane`, `StateGraphic`), not raw Material widgets, so light and dark both stay right. Icons come from `Ic` only (rounded Material icons).
- Keep it usable by keyboard. A drag gesture must use `kDragDevices` so a trackpad scroll never starts a drag.
- A bar that holds text and controls must not overflow in a narrow window: use `HeaderBar`, ellipsis on text, and test a narrow width.
- A dialog goes through `ModalBox` (it scrolls when the window is short).

**Data**

- Everything is saved by `AppStore` / `ServerStore` in the data folder ([data and storage](data-and-storage.md)). Do not add `shared_preferences`.
- Saved JSON only grows: add optional fields and keep reading old files.
- Secrets are not hidden on disk; do not pretend otherwise in the UI or the docs.

## Tests

`test/` has a file per area. `flutter test` must pass. Add or update tests with the change:

- logic in `core/` and `utils/` → plain unit tests;
- sessions and the connection lifecycle → use `McpInMemoryTransport` (see `test/mcp_session_test.dart`);
- widgets → `testWidgets`, wrapped in `MaterialApp` / `Material` / `RocketTheme` and `AppScope` when the widget reads app state; set `AppStore.homeOverride` to a temporary folder so tests never touch the real data folder.

For a bug fix, add a test that fails without the fix.

## Screenshots

When a change alters how a screen looks, regenerate the screenshots in the docs; see [building and releasing](building-and-releasing.md#regenerating-the-screenshots).

## Sending a change

1. Branch from `main`.
2. Make a focused change. Do not mix refactors with features.
3. Run `dart format`, `flutter analyze` and `flutter test`.
4. Update the docs and `ARCHITECTURE.md` when behaviour or structure changes.
5. Open a pull request that says what changed and why, with a screenshot for UI work.
