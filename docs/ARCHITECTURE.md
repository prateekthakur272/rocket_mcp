# Rocket MCP architecture

Rocket MCP is a Flutter desktop app (macOS, Windows, Linux), structured like its sibling project OpenRest. Read
[guidelines.md](guidelines.md) first: it is the engineering standard for every change.

## Layers

| Folder | Owns | May depend on |
|---|---|---|
| `core/` | Domain and data: models, storage, logging, and (as they are added) the MCP client and transports | `utils/` |
| `utils/` | `AppConfig`, `AppMetadata`, `Paths`, `UpdateChecker`, `IssueReport` | `core/logging`, `core/storage` |
| `theme/`, `platform/` | Palette and icons; operating-system access | `core/logging`, `utils/` |
| `components/` | Reusable widgets that know nothing about any feature | `theme/` |
| `app/` | `AppState`, the `Modal` list, `TitleMenuState` | `core/`, `platform/` |
| `features/*` | One folder per screen area | `app/`, `components/`, `core/`, `theme/`, `platform/` |
| `main.dart`, `features/shell` | Composition: assembles the features into the window | everything |

**`core/` never imports `app/`, `features/`, `components/`, `theme/` or `platform/`**, so it can be tested without a UI.

## Shell

- **State**: `AppState` is the single owner of application state; widgets read it through `AppScope`.
- **Dialogs**: cases of the sealed `Modal` class. Set `state.modal = const ModalX()`; `Modals` maps each case to its
  widget with an exhaustive `switch`.
- **Menus** are data (`AppMenus.build`). macOS turns them into the native menu bar in `main.dart`; Windows and Linux draw
  them in the title bar (`TitleMenus`).
- **Title bar**: `TitleBar` + `WindowChrome` (drag, double-click to maximize, window buttons, resize edges).
- **Status bar**: `StatusBar`. **Command palette**: `Palette` (add commands in its `build`).
- **Layout**: sidebar + `WorkspaceView`, whose request and response panes are stacked or side by side
  (`AppSettings.verticalLayout`, toggled with ⌘⇧L).
- **Updates**: `UpdateChecker` reads the GitHub releases page at startup and from Help → Check for Updates; the
  status-bar download icon and `UpdateAvailableDialog` report a newer version.

## Data on disk (`~/.rocketmcp`)

`settings.json`, `layout.json`, `prefs.json` (small flags such as the dismissed update), `window.json`, `rocketmcp.log`.
All of it goes through `AppStore`; all paths come from `Paths`. `shared_preferences` is not used.

## Where does new code go?

| I want to… | Put it in |
|---|---|
| Add a reusable widget | `components/` |
| Add a feature | `features/<name>/`, hooked into `features/shell` |
| Add a dialog | a case in `app/modal.dart`, the widget in its feature, a line in `features/shell/modals.dart` |
| Add a menu item | `AppMenus.build` in `features/shell/menus.dart` |
| Add a palette command | `features/shell/palette.dart` |
| Add a shortcut | `features/shell/key_handler.dart`, plus the menu entry and the Preferences "Shortcuts" list |
| Touch the operating system | `platform/` |
| Remember a small flag | `AppStore.setFlag` |
