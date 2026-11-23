import 'dart:io' as io;

import 'package:rocket_mcp/utils/app_config.dart';
import 'package:path/path.dart' as p;

/// Where the app keeps things on disk. Every path the app derives from the user's home folder is built here,
/// so the folder names and the home-folder rule exist exactly once.
final class Paths {
  const Paths._();

  /// `rocketmcp`: the app name in lower case, used for the data folder, log file and temp files.
  static String get _slug => 'rocketmcp';

  /// The user's home folder: `USERPROFILE` first on Windows, `HOME` first elsewhere; empty when neither is set.
  static String get home {
    final env = io.Platform.environment;
    return io.Platform.isWindows
        ? (env['USERPROFILE'] ?? env['HOME'] ?? '')
        : (env['HOME'] ?? env['USERPROFILE'] ?? '');
  }

  /// `~/.rocketmcp`: settings, saved state, secrets and the log.
  static String get dataDir => p.join(home, '.$_slug');

  /// `~/.rocketmcp/rocketmcp.log`, or the log inside [dir] when the data folder is overridden (tests).
  static String logFile([String? dir]) => p.join(dir ?? dataDir, '$_slug.log');

  /// `~/RocketMCP`: where new collections are created by default.
  static String get defaultCollectionsDir => p.join(home, AppConfig.NAME);

  /// A unique file path in the system temp folder, like `/tmp/rocketmcp-1731800000000000.png`.
  static String tempFile(String ext) => p.join(
    io.Directory.systemTemp.path,
    '$_slug-${DateTime.now().microsecondsSinceEpoch}$ext',
  );
}
