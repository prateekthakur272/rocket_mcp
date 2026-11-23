# Building and releasing

## Everyday commands

| Command | Does |
|---|---|
| `flutter pub get` | Fetches the dependencies |
| `flutter run -d macos` | Runs the app (use `-d windows` or `-d linux` on those systems) |
| `flutter analyze` | Static analysis; must report no issues |
| `flutter test` | All tests |
| `dart format lib test` | Formats the code |

## Building

```sh
flutter build macos --release      # build/macos/Build/Products/Release/rocket_mcp.app
flutter build windows --release    # build/windows/x64/runner/Release/
flutter build linux --release      # build/linux/x64/release/bundle/
```

The application id is `dev.prateekthakur.rocketmcp`. The version is set once, by `version:` in `pubspec.yaml` (`1.0.0+1` is version 1.0.0, build 1); the app reads it back at startup for the About dialog, the update check and the default User-Agent.

On macOS the app is **not sandboxed** (`macos/Runner/*.entitlements`). It needs to start local MCP server processes and write to `~/.rocketmcp`, which the sandbox would prevent.

Installers and code signing are not set up yet; builds are unsigned. On macOS, right-click the app and choose **Open** the first time.

## Releasing

The update check reads the latest release of the GitHub repository (`AppConfig.RELEASES_URL`). To publish a version:

1. Set `version:` in `pubspec.yaml`.
2. Run `flutter analyze` and `flutter test`.
3. Build for each system.
4. Create a GitHub release whose tag is the version (`v1.0.1`) and attach the builds. Users with an older version then see the update notice.

## Regenerating the screenshots

The pictures in `docs/screenshots/` are rendered by a test from the real UI, against a fictional demo weather server served from memory, so no personal data ends up in them.

```sh
GEN_SCREENSHOTS=1 flutter test test/screenshots/generate_docs_screenshots_test.dart
```

Without `GEN_SCREENSHOTS` the test is skipped, so a normal `flutter test` never touches the docs. The test loads the system's real fonts (San Francisco and Menlo on macOS), so run it on a Mac for the pictures to match. It writes these files:

| File | Shows |
|---|---|
| `welcome.png` | No servers yet |
| `onboarding.png` | The first-run tour |
| `not-connected.png` | A server that is not connected |
| `tools.png` | A tool call and its result |
| `tool-warnings.png` | The warnings popup |
| `tool-json.png` | The JSON body editor |
| `resources.png` | The Resources tab |
| `prompts.png` | The Prompts tab |
| `traffic.png` | The Traffic Inspector with a packet open |
| `logs.png` | Server Logs |
| `raw-jsonrpc.png` | Raw JSON-RPC |
| `add-server.png` | The Add MCP Server dialog |
| `command-palette.png` | The command palette |
| `preferences.png` | Preferences |
| `dark-side-by-side.png` | The dark theme with the response beside the request |

To add a screenshot, add a block to the test that builds the state, pumps the app with `_pumpApp` and calls `_capture`. The demo server (`_demoTransport`) is in the same file.
