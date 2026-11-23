# Rocket MCP architecture

Rocket MCP is a Flutter desktop app (macOS, Windows, Linux). `lib/main.dart` sets up the window, builds the root widget and the macOS menu bar; everything else is in `lib/`, split into layers. For the folder-by-folder tour see [project-structure.md](project-structure.md). [guidelines.md](guidelines.md) is the engineering standard every change follows.

## Layers

| Layer | Owns | May depend on |
|---|---|---|
| `core/` | The MCP client and transports, the data model, storage, logging | `utils/` |
| `utils/` | `AppConfig`, `AppMetadata`, `Paths`, `UpdateChecker`, `IssueReport`, JSON and URI-template helpers | `core/logging`, `core/storage` |
| `theme/`, `platform/` | The palette and icons; operating-system access | `core/logging`, `utils/` |
| `components/` | Reusable widgets that know nothing about any feature | `theme/`, `core/` (the model) |
| `app/` | `AppState`, `McpSession`, the dialog list | `core/`, `platform/` |
| `features/*` | One folder per screen area | `app/`, `components/`, `core/`, `theme/`, `platform/` |
| `main.dart`, `features/shell` | Composition: assembles the features into the window | everything |

**`core/` never imports `app/`, `features/`, `components/`, `theme/` or `platform/`.** Everything in it can be tested without a UI. No tool enforces this, so keep it true when you add code.

## State

- **`AppState`** (`app/app_state.dart`) is a `ChangeNotifier` and the single owner of application state: settings, the dialog that is showing, the sizes of the panels, the update that was found, the list of servers and one session per server. Widgets reach it through `AppScope`: `AppScope.of(context)` rebuilds on change, `AppScope.read(context)` does not.
- **`McpSession`** (`app/mcp_session.dart`) is the state of one server and also a `ChangeNotifier`. It owns the `McpClient`, the connection status, the fetched tools, resources, templates and prompts, the selections, the arguments being edited, the latest results, and the actions on them. A screen that shows one server listens to its session with a `ListenableBuilder` and rebuilds only itself.
- **Dialogs** are cases of the sealed `Modal` class. Setting `state.modal = const ModalX()` shows one; `Modals` (`features/shell/modals.dart`) maps every case to its widget with an exhaustive `switch`, so the compiler reports a dialog without a widget.
- **Menus** are data (`AppMenus.build`). On macOS `main.dart` turns them into the native menu bar; on Windows and Linux `TitleMenus` draws them in the title bar. One definition serves both.
- **Seams for tests.** `AppState` takes an optional `transportFactory`, and `McpSession` an optional `transportOverride`, so tests and the documentation screenshots run against an in-memory server instead of starting a process.

## The connection lifecycle

`McpSession.connect()`:

1. Sets the status to *connecting* and builds the transport from the server's configuration: `McpStdioTransport` (a child process), `McpSseTransport` or `McpStreamHttpTransport`.
2. Creates an `McpClient` on it and subscribes to its streams: traffic, server logs, standard error, and the *list changed* and *resource updated* notifications.
3. `client.connect()` sends `initialize`, stores the server's information and capabilities and sends `notifications/initialized`.
4. The status becomes *connected* and listeners are notified **at once**, so the workspace appears.
5. `_discover` then asks, **in parallel**, for tools, resources (and templates) and prompts, but only for the capabilities the server advertises (all three when it advertises none), plus a `ping` for the latency. The first resource and the first prompt are selected, and an item that needs no input is read or fetched. Each answer notifies, so each list fills in as it arrives.
6. Later `notifications/tools/list_changed` and the like trigger a refresh of just that list.

A failure at any point sets the status to *error*, keeps the message in `statusError` and closes the transport. `disconnect()` cancels the subscriptions and closes the client, which stops a stdio process.

### Writing to a stdio process

Several requests are sent at once after connecting. The transport therefore **queues its writes** and sends them one at a time: flushing a process's standard input binds the sink to a stream, and a second write during a flush throws. `test/stdio_transport_test.dart` guards this against a real process.

## The workspace

`WorkspaceView` shows, for the active server:

- the `ServerHeader` (status, name, address, actions);
- while connected, the `WorkspaceTabs` and the active tab's view; otherwise the `DisconnectedPanel` (connect, connecting, or the error);
- on the Tools tab, a `SplitPane` of the tool runner and the `ResponseViewer`; on the Traffic Inspector, the list and a `TrafficPacketView`; every other tab uses the full width.

The tool form is built from the tool's JSON schema (`ToolArgumentField`), validated in the view (`argumentsJsonProblem` for the JSON body, required arguments for the form) and run through `McpSession.executeTool`.

## Data on disk

All of it is in `~/.rocketmcp`, read and written by `AppStore` and `ServerStore`, with paths from `Paths`. See [data and storage](data-and-storage.md). The app does not use `shared_preferences`; a change that adds it should be rejected.

## Identity and version

- **`AppConfig`**: compile-time constants (name, vendor, links).
- **`AppMetadata`**: what the running app reports about itself, read at startup from the platform (`package_info_plus`). The version is written once, in `pubspec.yaml`.

## Conventions

- One responsibility per file; a file past a few hundred lines is a sign to split it by topic.
- Failures are never swallowed silently: `Log.warning` / `Log.error`, or `Log.orElse` for work that may fail. Never log secrets, environment values, headers or tool arguments.
- The saved JSON only grows: add optional fields and keep reading old files.
- A bar that mixes text and controls uses `HeaderBar` so it shrinks instead of overflowing; a dialog uses `ModalBox`, which scrolls when the window is short.
- Drag gestures use `kDragDevices` (mouse, touch and pen, not the trackpad), so a two-finger scroll never drags a divider.
- Icons are named once, in `theme/icons.dart` (`Ic`); use them by meaning.

## Tests

`test/` holds unit tests for the core (the client over an in-memory transport, the model, the session, JSON and URI-template helpers) and widget tests for the UI. Run `flutter test`. See [contributing](contributing.md#tests). `test/screenshots/` holds the generator for the documentation screenshots (skipped unless `GEN_SCREENSHOTS=1`).
