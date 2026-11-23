# Rocket MCP

A full-featured desktop MCP (Model Context Protocol) testing client, built with Flutter. Bundle id
`dev.prateekthakur.rocketmcp`; Dart package `rocket_mcp`.

Follow [docs/guidelines.md](docs/guidelines.md) for every change, and keep [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md)
true. Key rules: `core/` never imports UI layers; one responsibility per file; handle and log errors (`Log`), never swallow
them; never log secrets; add tests for logic; no new `shared_preferences`.

Commands: `flutter analyze`, `flutter test`, `flutter run -d macos`.
