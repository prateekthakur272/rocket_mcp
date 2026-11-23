# Project structure

Rocket MCP is a Flutter desktop app (macOS, Windows, Linux) written in Dart. There is one package, `rocket_mcp`.

```
rocket_mcp/
├── README.md
├── CLAUDE.md                    notes for AI coding assistants
├── pubspec.yaml                 dependencies, version
├── analysis_options.yaml        lints (flutter_lints)
├── assets/                      the app icon
├── .marketplace/                the app-marketplace listing (app-info.yaml, icon, screenshots)
├── lib/                         all Dart source (see below)
├── test/                        unit and widget tests; screenshots/ holds the docs screenshot generator
├── docs/                        documentation
│   └── screenshots/             images used by the docs
└── macos/  windows/  linux/     the Flutter runners
```

## `lib/`

Every import is a `package:rocket_mcp/...` import. The folder is the layer.

```
lib/
├── main.dart        entry point: window setup, the root widget, the macOS menu bar
├── app/             application state
├── core/            logic with no UI: the MCP client, storage, logging
├── features/        one folder per part of the app a user can point at
├── components/      reusable widgets
├── theme/           palette, themes, icons
├── platform/        operating-system access
└── utils/           small helpers and app-wide constants
```

### `app/`

| File | What it holds |
|---|---|
| `app_state.dart` | `AppState`, the single owner of state (a `ChangeNotifier`), and `AppScope`, the `InheritedNotifier` that hands it to widgets. Holds settings, the dialog showing, layout sizes, the list of servers and one `McpSession` per server |
| `mcp_session.dart` | `McpSession`: the state of one server. Its connection status, the fetched tools, resources and prompts, the selected items, tool arguments, the last results, and the actions that change them (connect, run a tool, read a resource, fetch a prompt…) |
| `modal.dart` | `Modal`, a sealed class with one case per dialog |
| `title_menu_state.dart` | Which in-window menu is open (Windows and Linux) |

### `core/`

| Folder | What it is |
|---|---|
| `mcp/` | `client.dart` (`McpClient`: JSON-RPC over a transport, the MCP requests and notifications, the traffic and log history), `transports.dart` (stdio, SSE, streamable HTTP and an in-memory transport for tests), `model.dart` (servers, tools, resources, prompts, results, messages) |
| `model/` | `AppSettings` and `ThemeMode` |
| `storage/` | `AppStore` (settings, layout, flags, window geometry, the data folder), `ServerStore` (servers, presets, Claude import and export) |
| `logging/` | `Log`: levels, tags and the log file |

### `features/`

| Folder | What it is |
|---|---|
| `shell/` | The window: layout, title bar and its menus, header (breadcrumb), status bar, command palette, key handler, the dialog layer, About and update dialogs |
| `sidebar/` | The server list and a server row |
| `workspace/` | The server header, the tabs, and the tab views: tools (with its argument fields), resources, prompts, traffic inspector and packet view, server logs, raw JSON-RPC, the response viewer and the disconnected panel |
| `servers/` | The add / edit server dialog and import / export |
| `preferences/` | The Preferences window |
| `developer/` | The Developer dialog |
| `dialogs/` | The first-run tour |

### `components/`, `theme/`, `platform/`, `utils/`

- **`components/`**: widgets that know nothing about any one feature: text and buttons (`T`, `Btn`, `IconBtn`, `IconBtnGroup`, `BadgeIconBtn`), inputs (`Field`, `AreaField`, `Toggle`), `ModalBox`, `HeaderBar`, `Breadcrumb`, `ResizablePane`, `SplitPane`, `EmptyState` and `StateGraphic`, `ItemTile`, overlays and menus, `JsonTree`, `CodeView`, `MarkdownView`.
- **`theme/`**: `RocketTheme` (the palette, light and dark) and `Ic`, the one place every icon is named.
- **`platform/`**: the `Platform` class: opening URLs and the file manager, the clipboard.
- **`utils/`**: `AppConfig` (name and links), `AppMetadata` (version read from the running app), `Paths`, `UpdateChecker`, `IssueReport`, JSON helpers, URI-template expansion.

## How the pieces fit

```
main.dart ──► features/shell ──► features/* ──► app ──► core ──► utils
                                      │                   ▲
                                      └──► components ──► theme
```

- `core/` imports nothing from `app/`, `features/`, `components/`, `theme/` or `platform/`. It can be tested without a UI.
- Features read and change state through `AppState` and the session. They do not call each other, except where one is built from another; `shell` assembles everything.
- Menus are data (`AppMenus.build`): macOS turns them into the native menu bar, Windows and Linux draw them in the title bar.
- Dialogs are cases of the `Modal` class; `Modals` picks the widget to draw with an exhaustive `switch`.

## Where does new code go?

| I want to… | Put it in |
|---|---|
| Add a reusable widget | `components/` |
| Add a feature or a workspace tab | `features/<name>/`, hooked into `features/shell` or `features/workspace/workspace_view.dart` |
| Add a dialog | a case in `app/modal.dart`, the widget in its feature, a line in `features/shell/modals.dart` |
| Add a menu item | `AppMenus.build` in `features/shell/menus.dart` |
| Add a palette command | `features/shell/palette.dart` |
| Add a shortcut | `features/shell/key_handler.dart`, plus the menu entry and the Preferences list |
| Add a new MCP request | `core/mcp/client.dart`, then an action on `McpSession` |
| Add an icon | `theme/icons.dart` |
| Remember a small flag | `AppStore.setFlag` |
| Touch the operating system | `platform/` |
