// ignore_for_file: constant_identifier_names

/// Static application configuration: the name, credits and links shown in the About and developer dialogs.
///
/// Compile-time constants only. What the running app reports about itself (version, build number, bundle id) is
/// read at runtime by `AppMetadata` in utils/app_metadata.dart.
final class AppConfig {
  const AppConfig._();

  static const String NAME = 'Rocket MCP';

  static const String VENDOR = 'Prateek Thakur';
  static const String DESCRIPTION =
      'A full-featured desktop client for testing Model Context Protocol (MCP) servers.';
  static const String HOMEPAGE =
      'https://github.com/prateekthakur272/rocket_mcp';
  static const String DEVELOPER_URL = 'https://github.com/prateekthakur272';

  /// GitHub's new-issue page of the project.
  static const String ISSUES_URL = '$HOMEPAGE/issues/new';
  static const String MORE_APPS_URL =
      'https://prateekthakur272.github.io/github-marketplace/';
  static const String TAGLINE =
      'A full-featured MCP testing client: connect to servers, call tools, read resources and inspect every message.';

  /// GitHub Releases page — opened when the user clicks "Download" in the update dialog.
  static const String RELEASES_URL = '$HOMEPAGE/releases/latest';

  /// GitHub REST API endpoint for the latest release — used by [UpdateChecker].
  static const String RELEASES_API_URL =
      'https://api.github.com/repos/prateekthakur272/rocket_mcp/releases/latest';
}
